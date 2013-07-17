# encoding: UTF-8

require 'mongo'
require 'json'
require 'zlib'
require 'uri'
require 'yaml'
require 'rubygems'
require 'net/ftp'

module HerokuMongoBackup

  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      rake_tasks do
        load "tasks/heroku_mongo_backup.rake"
      end
    end
  end

  require 's3_helpers'

  class Backup
    def chdir
      Dir.chdir("/tmp")
      begin
        Dir.mkdir("dump")
      rescue
      end
      Dir.chdir("dump")
    end

    def store
      backup = {}
  
      @db.collections.each do |col|
        backup['system.indexes.db.name'] = col.db.name if col.name == "system.indexes"
    
        records = []
    
        col.find().each do |record|
          records << record
        end

        backup[col.name] = records
      end
  
      marshal_dump = Marshal.dump(backup)
  
      file = File.new(@file_name, 'w')
      file.binmode
      file = Zlib::GzipWriter.new(file)
      file.write marshal_dump
      file.close
    end

    def load
      file = Zlib::GzipReader.open(@file_name)
      obj = Marshal.load file.read
      file.close

      obj.each do |col_name, records|
        next if col_name =~ /^system\./
    
        @db.drop_collection(col_name)
        dest_col = @db.create_collection(col_name)
    
        records.each do |record|
          dest_col.insert record
        end
      end
  
      # Load indexes here
      col_name = "system.indexes"
      dest_index_col = @db.collection(col_name)
      obj[col_name].each do |index|
        if index['_id']
          index['ns'] = index['ns'].sub(obj['system.indexes.db.name'], dest_index_col.db.name)
          dest_index_col.insert index
        end
      end
    end

    def db_connect
      uri = URI.parse(@url)
      connection = ::Mongo::Connection.new(uri.host, uri.port)
      @db = connection.db(uri.path.gsub(/^\//, ''))
      @db.authenticate(uri.user, uri.password) if uri.user
    end
    
    def ftp_connect
      @ftp = Net::FTP.new(ENV['FTP_HOST'])
      @ftp.passive = true
      @ftp.login(ENV['FTP_USERNAME'], ENV['FTP_PASSWORD'])
    end
    
    def ftp_upload
      @ftp.putbinaryfile(@file_name)
    end
    
    def ftp_download
      open(@file_name, 'w') do |file|
        file_content = @ftp.getbinaryfile(@file_name)
        file.binmode
        file.write file_content
      end
    end
    
    def s3_connect
      bucket            = ENV['S3_BACKUPS_BUCKET']
      if bucket.nil?
        bucket          = ENV['S3_BACKUP_BUCKET']
      end
      if bucket.nil?
        bucket          = ENV['S3_BACKUP']
      end
      if bucket.nil?
        bucket          = ENV['S3_BUCKET']
      end

      dir_name          = ENV['S3_BACKUP_DIR']
      if dir_name.nil?
        dir_name        = ENV['S3_BACKUP_DIRNAME']
      end
      if dir_name.nil?
        dir_name        = ENV['S3_BACKUP_DIR_NAME']
      end
      if dir_name.nil?
        dir_name        = 'backups'
      end
      @dir_name = dir_name

      access_key_id     = ENV['S3_KEY_ID']
      if access_key_id.nil?
        access_key_id   = ENV['S3_KEY']
      end
      if access_key_id.nil?
        access_key_id   = ENV['AWS_ACCESS_KEY_ID']
      end

      secret_access_key = ENV['S3_SECRET_KEY']
      if secret_access_key.nil?
        secret_access_key = ENV['S3_SECRET']
      end
      if secret_access_key.nil?
        secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
      end

      @bucket = HerokuMongoBackup::s3_connect(bucket, access_key_id, secret_access_key)
    end

    def s3_upload
      HerokuMongoBackup::s3_upload(@bucket, @dir_name, @file_name)
    end

    def s3_download
      open(@file_name, 'w') do |file|
        file_content = HerokuMongoBackup::s3_download(@bucket, @dir_name, @file_name)
        file.binmode
        file.write file_content
      end
    end

    def initialize connect = true
      @file_name = Time.now.strftime("%Y-%m-%d_%H-%M-%S.gz")
  
      if( ['production', 'staging'].include?(ENV['RAILS_ENV'] || ENV['RACK_ENV']) )

        #config_template = ERB.new(IO.read("config/mongoid.yml"))
        #uri = YAML.load(config_template.result)['production']['uri']
        uri = ENV['MONGO_URL']

        if uri.nil?
          uri = ENV['MONGOHQ_URL']
        end
        if uri.nil?
          uri = ENV['MONGOLAB_URI']
        end          
      
      else
        mongoid_config  = YAML.load_file("config/mongoid.yml")
        config = {}
        defaults        = mongoid_config['defaults']
        dev_config      = mongoid_config['development']

        config.merge!(defaults) unless defaults.nil?
        config.merge!(dev_config)

        host            = config['host']
        port            = config['port']
        database        = config['database']
        uri = "mongodb://#{host}:#{port}/#{database}"

        if uri == 'mongodb://:/' # new mongoid version 3.x
          mongoid_config  = YAML.load_file("config/mongoid.yml")
          dev_config      = mongoid_config['development']['sessions']['default']
          host_port       = dev_config['hosts'].first
          database        = dev_config['database']
          uri = "mongodb://#{host_port}/#{database}"
        end
      end
  
      @url = uri
  
      puts "Using database: #{@url}"
  
      self.db_connect

      if connect
        if ENV['UPLOAD_TYPE'] == 'ftp'
          self.ftp_connect
        else
          self.s3_connect
        end
      end
    end

    def backup files_number_to_leave=0
      self.chdir    
      self.store

      if ENV['UPLOAD_TYPE'] == 'ftp'
        self.ftp_upload
        @ftp.close
      else
        self.s3_upload
      end

      if files_number_to_leave > 0
        HerokuMongoBackup::remove_old_backup_files(@bucket, @dir_name, files_number_to_leave)
      end
    end
    
    def restore file_name, download_file = true
      @file_name = file_name
  
      self.chdir
      
      if download_file
        if ENV['UPLOAD_TYPE'] == 'ftp'
          self.ftp_download
          @ftp.close
        else
          self.s3_download
        end
      end

      self.load
    end
  end
end

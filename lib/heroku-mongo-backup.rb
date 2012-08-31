# encoding: UTF-8

require 'mongo'
require 'bson'
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
        bucket          = ENV['S3_BUCKET']
      end

      access_key_id     = ENV['S3_KEY_ID']
      if access_key_id.nil?
        access_key_id   = ENV['S3_KEY']
      end

      secret_access_key = ENV['S3_SECRET_KEY']
      if secret_access_key.nil?
        secret_access_key = ENV['S3_SECRET']
      end

      @bucket = HerokuMongoBackup::s3_connect(bucket, access_key_id, secret_access_key)
    end

    def s3_upload
      HerokuMongoBackup::s3_upload(@bucket, @file_name)
    end

    def s3_download
      open(@file_name, 'w') do |file|
        file_content = HerokuMongoBackup::s3_download(@bucket, @file_name)
        file.binmode
        file.write file_content
      end
    end

    def initialize
      @file_name = Time.now.strftime("%Y-%m-%d_%H-%M-%S.gz")
  
      if((ENV['RAILS_ENV'] || ENV['RACK_ENV']) == 'production')
        #config_template = ERB.new(IO.read("config/mongoid.yml"))
        #uri = YAML.load(config_template.result)['production']['uri']
        uri = ENV['MONGO_URL']
      else
        mongoid_config  = YAML.load_file("config/mongoid.yml")
        config = {}
        defaults          = mongoid_config['defaults']
        dev_config      = mongoid_config['development']

        config.merge!(defaults) unless defaults.nil?
        config.merge!(dev_config)

        host            = config['host']
        port            = config['port']
        database        = config['database']
        uri = "mongodb://#{host}:#{port}/#{database}"
      end
  
      @url = uri
  
      puts "Using databased: #{@url}"
  
      self.db_connect

      if ENV['UPLOAD_TYPE'] == 'ftp'
        self.ftp_connect
      else
        self.s3_connect
      end
    end

    def backup
      self.chdir    
      self.store

      if ENV['UPLOAD_TYPE'] == 'ftp'
        self.ftp_upload
        @ftp.close
      else
        self.s3_upload
      end
    end
    
    def restore file_name
      @file_name = file_name
  
      self.chdir
      
      if ENV['UPLOAD_TYPE'] == 'ftp'
        self.ftp_download
        @ftp.close
      else
        self.s3_download
      end
      self.load
    end
  end
end


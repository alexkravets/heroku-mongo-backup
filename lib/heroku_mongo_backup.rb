# encoding: UTF-8

require 'mongo'
require 'bson'
require 'json'
require 'zlib'
require 'uri'
require 'yaml'
require 'rubygems'
require 's3'

module HerokuMongoBackup
  require 'heroku_mongo_backup/railtie' if defined?(Rails)

  class Backup
    def chdir
      Dir.chdir("tmp")
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

    def connect
      uri = URI.parse(@url)
      connection = ::Mongo::Connection.new(uri.host, uri.port)
      @db = connection.db(uri.path.gsub(/^\//, ''))
      @db.authenticate(uri.user, uri.password) if uri.user
    end

    def s3_connect
      bucket            = ENV['S3_BUCKET']
      access_key_id     = ENV['S3_KEY_ID']
      secret_access_key = ENV['S3_SECRET_KEY']

      service = S3::Service.new(:access_key_id => access_key_id,
                                :secret_access_key => secret_access_key)
      @bucket = service.buckets.find(bucket)
    end

    def s3_upload
      object = @bucket.objects.build("backups/#{@file_name}")
      object.content = open(@file_name)
      object.save
    end

    def s3_download
      open(@file_name, 'w') do |file|
        object = @bucket.objects.find("backups/#{@file_name}")
        file.write object.content
      end
    end

    def initialize
      @file_name = Time.now.strftime("%Y-%m-%d_%H-%M-%S.gz")
  
      if ENV['RAILS_ENV'] == 'production'
        uri = YAML.load_file("config/mongoid.yml")['production']['uri']
      else
        config = YAML.load_file("config/mongoid.yml")['development']
        uri = "mongodb://#{config['host']}:#{config['port']}/#{config['database']}"
      end
  
      @url = uri
  
      puts "Using databased: #{@url}"
  
      self.connect
      self.s3_connect
    end

    def backup
      self.chdir    
      self.store
      self.s3_upload
    end

    def restore file_name
      @file_name = file_name
  
      self.chdir
      self.s3_download
      self.load
    end
  end
end
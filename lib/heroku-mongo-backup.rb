# encoding: UTF-8

#require 'mongo'
require 'json'
require 'zlib'
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
      session = ::Mongoid::Clients.default

      backup = {}

      session.collections.each do |collection|
        backup[collection.name] = []
        collection.find().each { |doc| backup[collection.name] << doc }
      end

      marshal_dump = Marshal.dump(backup)

      file = File.new(@file_name, 'w')
      file.binmode
      file = Zlib::GzipWriter.new(file)
      file.write marshal_dump
      file.close
    end

    def load
      session = ::Mongoid::Sessions.default

      file   = Zlib::GzipReader.open(@file_name)
      backup = Marshal.load file.read
      file.close

      Mongoid.purge!

      backup.each do |collection_name, documents|
        puts collection_name
        documents.each { |doc| session[collection_name].insert(doc) }
      end

      Rake::Task['db:mongoid:create_indexes'].invoke
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

    def initialize connect=true
      @file_name = Time.now.strftime("%Y-%m-%d_%H-%M-%S.gz")

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
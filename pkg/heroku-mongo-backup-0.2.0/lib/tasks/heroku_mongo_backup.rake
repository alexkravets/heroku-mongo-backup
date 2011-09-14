# encoding: UTF-8

namespace :mongo do
  desc "Backup prodution database and store it on S3.\n
        Example of usage: rake mongo:backup"
  task :backup => :environment do
    HerokuMongoBackup::Backup.new.backup
  end
  
  desc "Restore command gets backup file from S3 server and pushes data to production db.\n
        Example of usage: rake mongo:restore FILE=<backup-file.gz>"
  task :restore => :environment do
    if ENV['FILE']
      HerokuMongoBackup::Backup.new.restore ENV['FILE']
    else
      puts "Please provide backup file to restore from. Thanks!"
    end
  end
end
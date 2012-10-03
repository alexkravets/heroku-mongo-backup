# encoding: UTF-8

namespace :mongo do
  desc "Backup prodution database and store it on S3.\n
        Example of usage: rake mongo:backup OR rake mongo:backup MAX_BACKUPS=7"
  task :backup => :environment do
    if ENV['MAX_BACKUPS']
      HerokuMongoBackup::Backup.new.backup(ENV['MAX_BACKUPS'].to_i)
    else
      HerokuMongoBackup::Backup.new.backup
    end
  end
  
  desc "Restore command gets backup file from S3 server or local file and pushes data to production db.\n
        Example of usage: rake mongo:restore FILE=<backup-file.gz>"
  task :restore => :environment do
    if ENV['FILE']
      HerokuMongoBackup::Backup.new.restore ENV['FILE']
    elsif ENV['LOCAL']
      HerokuMongoBackup::Backup.new(false).restore ENV['LOCAL'], false
    else
      puts "\n* --------------------------------------------------------------- *\n" +
             "|  Provide backup file to restore from:                           |\n" +
             "|                                                                 |\n" +
             "|    rake mongo:restore FILE=<backup-file.gz>                     |\n" +
             "|                                                                 |\n" +
             "|  If backup file is already downloaded:                          |\n" +
             "|                                                                 |\n" +
             "|    rake mongo:restore LOCAL=/absolute/path/to/<backup-file.gz>  |\n" +
             "|                                                                 |\n" +
             "* --------------------------------------------------------------- *\n\n"
    end
  end
end
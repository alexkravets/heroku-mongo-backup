# coding: UTF-8

namespace :mongo do
  desc "Mongo backup and restore commands.\n\tBackup: rake mongo:backup\n\tRestore: rake mongo:restore FILE=<backup-file.gz>"
  
  task :backup => [:environment] do
    Heroku::Mongo::Backup.new.backup
  end
  
  task :restore => [:environment] do
    if ENV['FILE']
      Heroku::Mongo::Backup.new.restore ENV['FILE']
    else
      puts "Please provide backup file to restore from. Thanks!"
    end
  end
end
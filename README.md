ABOUT
=====

**heroku-mongo-backup** is a ruby library that backups mongo database in Heroku environment.

*Why not to use regular mongodump command?* - mongodump command is not available on Heroku side. To backup database third party service should be used.

*heroku-mongo-backup* simply does the job using cron:

1. Backups all db collections to the single file in _tmp_ folder;

2. Gunzip the file;

3. Pushes gzipped file to the Amazon S3 server;


HOW TO SETUP
============

1. Add library to the Gemfile:

    gem "heroku-mongo-backup"
    # OR FROM GITHUB
    gem "heroku-mongo-backup", :git => 'git://github.com/alexkravets/heroku-mongo-backup.git'

2. Add backup task to _/lib/tasks/cron.rake_ file:

    require 'heroku_mongo_backup'
    desc "This task is called by the Heroku cron add-on"
    task :cron => :environment do
      if Time.now.hour == 0 # run at midnight
        HerokuMongoBackup::Backup.new.backup
      end
    end

3. Set Heroku environment variables:
  
    heroku config:add S3_BUCKET=<value> S3_KEY_ID=<value> S3_SECRET_KEY=<value> MONGO_URL=<value>

First three are Amazon S3 auth settings and the last one should be copy of *MONGOHQ_URI* or *MONGOLAB_URI* depending on what addon is used for mongo. *MONGO_URL* is a variable which is used also for heroku-mongo-sync command.

That's all.


RAKE COMMANDS
=============

Backup command:

  heroku rake mongo:backup
  
Restore command:

  heroku rake mongo:restore FILE=<backup-file.gz>


Copyright (c) 2011 Alex Kravets, released under the MIT license
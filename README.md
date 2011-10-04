# heroku-mongo-backup — rake task backups mongo database on Heroku and pushes it to S3

> Why not to use regular mongodump command?

*mongodump* command is not available on Heroku side. To backup database third party service should be used. If you don't want to setup third party for every project *heroku-mongo-backup* may be helpful.

*heroku-mongo-backup* does:

1. Backups all db collections to the single file in _tmp_ folder;
2. Gunzip the file;
3. Pushes gzipped file to the Amazon S3 server;


## Setup and configuration

1. Add library to the Gemfile:

```gem "heroku-mongo-backup"``` or ```gem "heroku-mongo-backup", :git => 'git://github.com/alexkravets/heroku-mongo-backup.git'```

2. Add backup task to _/lib/tasks/cron.rake_ file:

```
require 'heroku_mongo_backup'

desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  if Time.now.hour == 0 # run at midnight
    HerokuMongoBackup::Backup.new.backup
  end
end
```

3. Set Heroku environment variables:

```heroku config:add S3_BUCKET=_value_ S3_KEY_ID=_value_ S3_SECRET_KEY=_value_ MONGO_URL=_value_```

First three are Amazon S3 auth settings and the last one should be copy of *MONGOHQ_URI* or *MONGOLAB_URI* depending on what addon is used for mongo. *MONGO_URL* is a variable which is used also for heroku-mongo-sync command.

**That's it.**


### Rake commands

Backup command: ```heroku rake mongo:backup```
Restore command: ```heroku rake mongo:restore FILE=backup-file-name.gz```

Copyright (c) 2011 Alex Kravets, released under the MIT license
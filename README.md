# heroku-mongo-backup — backup mongodb and push it to S3 on Heroku

> Why not to use regular mongodump command?

*mongodump* command is not available on Heroku side. To backup database third party service should be used. If you don't want to setup third party for every project *heroku-mongo-backup* may be helpful.

**heroku-mongo-backup** does:

1. Backup db collections to the single file;
2. Gunzip the file;
3. Pushes backup to the specified S3 bucket;


## Setup and configuration

Add library to the ```Gemfile```:

```gem "heroku-mongo-backup"``` or ```gem "heroku-mongo-backup", :git => 'git://github.com/alexkravets/heroku-mongo-backup.git'```

**heroku-mongo-backup** requires ```s3``` or ```aws-s3``` library. So one of those should be in ```Gemfile```. If there is no any of these two, add ```aws-s3```.

Add backup task to ```/lib/tasks/cron.rake``` file:

```
require 'heroku_mongo_backup'

desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  if Time.now.hour == 0 # run at midnight
    HerokuMongoBackup::Backup.new.backup
  end
end
```

Set Heroku environment variables:

```heroku config:add S3_BUCKET=_value_ S3_KEY_ID=_value_ S3_SECRET_KEY=_value_ MONGO_URL=_value_```

First three are Amazon S3 auth settings and the last one should be copy of *MONGOHQ_URI* or *MONGOLAB_URI* depending on what heroku add-on is used for mongo. *MONGO_URL* is a variable which is used also for **heroku-mongo-sync** command.

**Rake commands:**

* ```heroku rake mongo:backup```
* ```heroku rake mongo:restore FILE=backup-file-name.gz```


# License (MIT)

Copyright (c) 2011 Alex Kravets <a@alexkravets.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

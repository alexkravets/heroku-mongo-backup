## heroku-mongo-backup *— backup mongodb on Heroku and push it to S3 or FTP storage*

**heroku-mongo-backup** does:

1. Backup mongodb collections to one file;
2. Compress backup file with gzip;
3. Push backup to the specified S3 bucket or FTP server;

> Why not mongodump command?

*mongodump* command is not available on Heroku side. If you don't want to setup third party backup service for every project *heroku-mongo-backup* may be helpful.


## Configuration

Add gem to the ```Gemfile```: ```gem "heroku-mongo-backup"``` - if everything's okay ```rake -T``` command should show ```rake mongo:backup``` rake tasks.

For S3 support **heroku-mongo-backup** requires ```s3``` or ```aws-s3``` library. One of those should be in ```Gemfile```, if any of those two is present add ```aws-s3```.

Configure heroku scheduler to run ```mongo:backup``` rake task. Or if cron is used add backup task to ```/lib/tasks/cron.rake``` file:

```
desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  Rake::Task['mongo:backup'].invoke
end
```

Set Heroku environment variables:

```heroku config:add S3_BACKUPS_BUCKET=_value_ S3_KEY_ID=_value_ S3_SECRET_KEY=_value_ MONGO_URL=_value_```

First three are Amazon S3 auth settings and the last one should be copy of *MONGOHQ_URI* or *MONGOLAB_URI* depending on what heroku add-on is used for mongo. *MONGO_URL* is a variable which is used also for **heroku-mongo-sync** command.

For FTP set these variables:

```heroku config:add UPLOAD_TYPE=ftp FTP_HOST=_host_ FTP_PASSWORD=_pass_ FTP_USERNAME=_user_```


## Rake Commands

* ```heroku rake mongo:backup```
* ```heroku rake mongo:restore FILE=backup-file-name.gz```


## Contributors

1. [alexkravets@slatestudio.com](http://slatestudio.com "Slate Studio") - gem itself with S3 support
2. [matyi](https://github.com/matyi "Matyi - GitHub Profile") - FTP support
3. [stefl](http://stef.io "Stef Lewandowski") - Rails is not required for production

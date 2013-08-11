## heroku-mongo-backup *— backup mongodb on Heroku and push it to S3 or FTP storage*

**heroku-mongo-backup** does:

1. Backup mongodb collections to one file;
2. Compress backup file with gzip;
3. Push backup to the specified S3 bucket or FTP server;

> Why not mongodump command?

*mongodump* command is not available on Heroku side. If you don't want to setup third party backup service for every project *heroku-mongo-backup* may be helpful.


## Configuration

Add gem to the ```Gemfile```: ```gem "heroku-mongo-backup"``` - if everything's okay ```rake -T``` command should show ```rake mongo:backup``` rake tasks.

For S3 support **heroku-mongo-backup** requires ```s3``` or ```aws-s3``` or ```fog``` library. One of those should be in ```Gemfile```, if you don't care add ```fog``` it's seems to be the most advanced.

Configure heroku scheduler to run ```mongo:backup``` rake task. Or if cron is used add backup task to ```/lib/tasks/cron.rake``` file:

```
desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  Rake::Task['mongo:backup'].invoke
end
```

Set Heroku environment variables:

```heroku config:add S3_BACKUPS_BUCKET=_value_ S3_KEY_ID=_value_ S3_SECRET_KEY=_value_ MONGO_URL=_value_```

On MONGO_URL place anyone of these is assaptable: *MONGOHQ_URI* or *MONGOLAB_URI*.

For FTP set these variables:

```heroku config:add UPLOAD_TYPE=ftp FTP_HOST=_host_ FTP_PASSWORD=_pass_ FTP_USERNAME=_user_```


## Rake Commands

* ```heroku run rake mongo:backup```

If you want to automatically remove old backup files pass ```MAX_BACKUPS``` parameter to the rake command:

* ```heroku run rake mongo:backup MAX_BACKUPS=7```

If you're uploading to S3, backup files will be stored as ```backups/YYYY-MM-DD_hh-mm-ss.gz``` by default. To change the directory name, pass in the ```S3_BACKUP_DIR``` parameter:

* ```heroku run rake mongo:backup S3_BACKUP_DIR=daily```
* Backup files would then be stored as ```daily/backup-file-name.gz``` instead of ```backups/backup-file-name.gz```.

Restore from backup:

* ```heroku run rake mongo:restore FILE=backup-file-name.gz```

If you want to restore from local file run:

* ```rake mongo:restore LOCAL=/absolute/path/to/<backup-file.gz>```

For Rails 2 add this to your Rakefile to import rake tasks:

```import File.expand_path(File.join(Gem.datadir('heroku-mongo-backup'), '..', '..', 'lib', 'tasks', 'heroku_mongo_backup.rake'))```

## Gem Contributors

1. [alexkravets - slatestudio.com](http://slatestudio.com "Slate Studio") - gem itself with S3 support
2. [matyi](https://github.com/matyi "Matyi - GitHub Profile") - FTP support
3. [stefl - stef.io](http://stef.io "Stef Lewandowski") - Rails is not required for production
4. [moonhouse - moonhouse.se](http://www.moonhouse.se/ "David Hall") - default config improvement
5. [wolfpakz](https://github.com/wolfpakz "Dan Porter") - Rails2 support
6. [solacreative](http://sola-la.com/creative "Taro Murao") - Max backups feature for aws/s3 and s3 gems
7. [aarti](https://github.com/aarti "aarti") - minor fixes
8. [strayduy](https://github.com/strayduy "strayduy") - [Configurable S3 directory name](https://github.com/alexkravets/heroku-mongo-backup/pull/17)





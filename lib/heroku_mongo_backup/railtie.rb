require 'heroku_mongo_backup'
require 'rails'

module HerokuMongoBackup
  class Railtie < Rails::Railtie
    railtie_name :heroku_mongo_backup

    rake_tasks do
      load "tasks/heroku_mongo_backup.rake"
    end
  end
end
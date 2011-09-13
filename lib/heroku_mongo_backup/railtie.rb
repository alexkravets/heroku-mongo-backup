# encoding: UTF-8

require 'heroku_mongo_backup'
require 'rails'

module HerokuMongoBackup
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/heroku_mongo_backup.rake"
    end
  end
end
require 'heroku_mongo_backup'
require 'rails'

module Heroku
  module Mongo
    class Railtie < Rails::Railtie
      railtie_name :heroku_mongo_backup

      rake_tasks do
        load "tasks/heroku_mongo_backup.rake"
      end
    end
  end
end
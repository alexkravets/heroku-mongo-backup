Gem::Specification.new do |s|
  s.name    = 'heroku-mongo-backup'
  s.version = '0.1.0'
  s.summary = 'Rake task for backing up mongo database on heroku and push it to S3.'
  s.description = 'Rake task for backing up mongo database on heroku and push it to S3.'

  s.author   = 'Alex Kraves'
  s.email    = 'mail@alexkravets.com'
  s.homepage = 'https://github.com/alexkravets/heroku-mongo-backup'

  # These dependencies are only for people who work on this gem
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'

  # Include everything in the lib folder
  s.files = Dir['lib/**/*']

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end
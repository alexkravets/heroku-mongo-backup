Gem::Specification.new do |s|
  s.name    = 'heroku-mongo-backup'
  s.version = '0.3.7'
  s.summary = 'Rake task backups mongo database on Heroku and push gzipped file to Amazon S3 or FTP.'
  s.description = 'Rake task for backing up mongo database on heroku and push it to S3 or FTP. Library can be used as rake task or be easily integrated into daily cron job.'

  s.authors  = ['Alex Kravets', 'matyi', 'Stef Lewandowski']
  s.email    = 'santyor@gmail.com'
  s.homepage = 'https://github.com/alexkravets/heroku-mongo-backup'

  # These dependencies are only for people who work on this gem
  s.add_development_dependency  'rspec'
  s.add_development_dependency  'mocha'
  s.add_development_dependency  'crack'

  # Include everything in the lib folder
  s.files = Dir['lib/**/*']

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end

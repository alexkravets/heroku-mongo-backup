Gem::Specification.new do |s|
  s.name    = 'heroku-mongo-backup'
  s.version = '0.3.9'
  s.summary = 'Rake task backups mongo database on Heroku and push gzipped file to Amazon S3 or FTP.'
  s.description = 'Rake task for backing up mongo database on heroku and push it to S3 or FTP. Library can be used as rake task or be easily integrated into daily cron job.'

  s.authors  = ['Alex Kravets', 'matyi', 'Stef Lewandowski', 'David Hall']
  s.email    = 'santyor@gmail.com'
  s.homepage = 'https://github.com/alexkravets/heroku-mongo-backup'

  s.files = Dir['lib/**/*']

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end

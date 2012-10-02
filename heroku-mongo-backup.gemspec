Gem::Specification.new do |s|
  s.name    = 'heroku-mongo-backup'
  s.version = '0.4.1'
  s.summary = 'Rake task backups mongo database on Heroku and push gzipped file to Amazon S3 or FTP.'
  s.description = 'Rake task for backing up mongo database on heroku and push it to S3 or FTP. Library can be used as rake task or be easily integrated into daily cron job.'

  s.authors  = ['Alex Kravets', 'matyi', 'Stef Lewandowski', 'David Hall', 'Dan Porter']
  s.email    = 'santyor@gmail.com'
  s.homepage = 'https://github.com/alexkravets/heroku-mongo-backup'

  s.require_paths = ["lib"]
  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'

  s.add_runtime_dependency 'mongo'
end

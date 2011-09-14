require 'rubygems/package_task'

spec = Gem::Specification.load(Dir['*.gemspec'].first)
gem = Gem::PackageTask.new(spec)
gem.define()

desc "Push gem to rubygems.org"
task :push => :gem do
  sh "gem push pkg/heroku-mongo-backup-0.2.0.gem"
end
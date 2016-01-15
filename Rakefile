# encoding: utf-8

require 'rubygems'

require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler'
require 'rubygems'

#require 'rubygems/package_task'

Jeweler::Tasks.new do |s|
  s.name = 'activeconfig'
  s.author = 'Jeremy Lawler'
  s.email = 'jeremylawler@gmail.com'
  s.homepage = 'http://jlawler.github.com/activeconfig/'
  s.summary = 'An extremely flexible configuration system'
  s.description = 'An extremely flexible configuration system.
Has the ability for certain values to be "overridden" when conditions are met.
For example, you could have your production API keys only get read when the Rails.env == "production"'
  s.authors = ["Jeremy Lawler"]
end

Jeweler::RubygemsDotOrgTasks.new

task :rdoc do
  sh "rm -rf #{File.dirname(__FILE__)}/doc"
  sh "cd lib && rdoc -o ../doc " 
end

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.verbose = true
  t.warning = true
  t.pattern = 'test/**/*_test.rb'
end

task :default => :test

# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "activeconfig"
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Lawler"]
  s.date = "2012-08-27"
  s.description = "An extremely flexible configuration system.\ns the ability for certain values to be \"overridden\" when conditions are met.\nr example, you could have your production API keys only get read when the Rails.env == \"production\""
  s.email = "jeremylawler@gmail.com"
  s.executables = ["active_config"]
  s.files = [
    "Gemfile",
    "Rakefile",
    "VERSION.yml",
    "activeconfig.gemspec",
    "bin/active_config",
    "lib/active_config.rb",
    "lib/active_config/hash_config.rb",
    "lib/active_config/hash_weave.rb",
    "lib/active_config/suffixes.rb",
    "lib/active_config_rails.rb",
    "lib/active_config_rails/templates/active_config_initializer.rb",
    "lib/active_config_rails/templates/database.yml",
    "lib/active_config_rails/templates/rails.yml",
    "lib/activeconfig.rb",
    "test/active_config_collision_test.rb",
    "test/active_config_multi_test.rb",
    "test/active_config_test.rb",
    "test/active_config_test/global.yml",
    "test/active_config_test/test.yml",
    "test/active_config_test/test_GB.yml",
    "test/active_config_test/test_US.yml",
    "test/active_config_test/test_config.yml",
    "test/active_config_test/test_local.yml",
    "test/active_config_test/test_production.yml",
    "test/active_config_test_collision/patha/test.yml",
    "test/active_config_test_collision/pathb/test.yml",
    "test/active_config_test_collision/pathb/test_local.yml",
    "test/active_config_test_multi/patha/test.yml",
    "test/active_config_test_multi/pathb/test_local.yml",
    "test/env_test.rb"
  ]
  s.homepage = "http://jlawler.github.com/activeconfig/"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "An extremely flexible configuration system"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.3"])
    else
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
      s.add_dependency(%q<aws-s3>)
    end
  else
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
    s.add_dependency(%q<aws-s3>)
  end
end


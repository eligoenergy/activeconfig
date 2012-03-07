# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "activeconfig"
  s.version = "0.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Lawler"]
  s.date = "2011-11-07"
  s.email = "jlawler@cashnetusa.com"
  s.executables = ["active_config"]
  s.files = [
    ".gitignore",
     "Rakefile",
     "VERSION.yml",
     "activeconfig.gemspec",
     "bin/active_config",
     "lib/active_config.rb",
     "lib/active_config/hash_config.rb",
     "lib/active_config/hash_weave.rb",
     "lib/active_config/suffixes.rb",
     "lib/cnu_config.rb",
     "pkg/activeconfig-0.1.4.gem",
     "pkg/activeconfig-0.2.0.gem",
     "pkg/activeconfig-0.3.0.gem",
     "pkg/activeconfig-0.4.0.gem",
     "pkg/activeconfig-0.4.1.gem",
     "pkg/activeconfig-0.5.0.gem",
     "pkg/activeconfig-0.5.1.gem",
     "test/active_config_test.rb",
     "test/active_config_test/global.yml",
     "test/active_config_test/test.yml",
     "test/active_config_test/test_GB.yml",
     "test/active_config_test/test_US.yml",
     "test/active_config_test/test_config.yml",
     "test/active_config_test/test_local.yml",
     "test/active_config_test/test_production.yml",
     "test/active_config_test_multi.rb",
     "test/active_config_test_multi/patha/test.yml",
     "test/active_config_test_multi/pathb/test_local.yml",
     "test/cnu_config_test.rb",
     "test/cnu_config_test/global.yml",
     "test/cnu_config_test/test.yml",
     "test/cnu_config_test/test_GB.yml",
     "test/cnu_config_test/test_US.yml",
     "test/cnu_config_test/test_local.yml",
     "test/env_test.rb"
  ]
  s.homepage = "http://jlawler.github.com/activeconfig/"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "An extremely flexible configuration system"
  s.test_files = [
    "test/env_test.rb",
     "test/active_config_test_multi.rb",
     "test/cnu_config_test.rb",
     "test/active_config_test.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

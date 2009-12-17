#!/usr/bin/env ruby
require 'pp'
# TEST_CONFIG_BEGIN
# enabled: true
# TEST_CONFIG_END

# Test target dependencies

# even if a gem is installed, load cnu_config and active_config locally
dir = File.dirname __FILE__
$LOAD_PATH.unshift File.join(dir, "..", "lib")

# Configure ActiveConfig to use our test config files.
RAILS_ENV = 'development'
ENV['ACTIVE_CONFIG_PATH'] = File.expand_path(File.dirname(__FILE__) + "/active_config_test/")
ENV.delete('ACTIVE_CONFIG_OVERLAY') # Avoid gb magic.

# Test environment.
require 'rubygems'
# gem 'activesupport'
require 'active_support'

# Test target
require 'active_config'

# Test dependencies
require 'test/unit'
require 'fileutils' # FileUtils.touch
require 'benchmark'

class ActiveConfig::Test < Test::Unit::TestCase
  def active_config
    @active_config||= ActiveConfig.new :suffixes  =>[
      nil, 
      [:overlay, nil], 
      [:local], 
      [:overlay, [:local]], 
      :config, 
      [:overlay, :config], 
      :local_config, 
      [:overlay, :local_config], 
      :hostname, 
      [:overlay, :hostname], 
      [:hostname, :config_local], 
      [:overlay, [:hostname, :config_local]]
    ] 
  end

  def setup
    super
    dir = File.expand_path(File.dirname(__FILE__))
    test_file  = File.join(dir, 'active_config_test_file', 'test.yml')

    @active_config = ActiveConfig.new :path => nil, :file => test_file

    active_config._flush_cache
    active_config._verbose = nil # default
    active_config.reload(true)
    active_config._reload_disabled = nil # default
    active_config._reload_delay = nil # default
  end

  def teardown
    @active_config = nil
    super
  end

  def test_basic
    assert_equal 101, active_config.using_array_index
    assert_equal 3, active_config.level_1.b
  end
end

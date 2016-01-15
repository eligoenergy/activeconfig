#!/usr/bin/env ruby
$:.unshift File.expand_path("../../lib",__FILE__)
ENV['ACTIVE_CONFIG_PATH']=[File.expand_path("../active_config_test_multi/patha",__FILE__),File.expand_path("../active_config_test_multi/pathb",__FILE__)].join(':')

# TEST_CONFIG_BEGIN
# enabled: true
# TEST_CONFIG_END

# Test target dependencies

# even if a gem is installed, load cnu_config and active_config locally
dir = File.dirname __FILE__
$LOAD_PATH.unshift File.join(dir, "..", "lib")

# Test environment.
require 'rubygems'

# Test target
require 'active_config'

# Test dependencies
require 'test/unit'
require 'fileutils' # FileUtils.touch
require 'benchmark'

class ActiveConfig::TestMulti < Test::Unit::TestCase
  attr_accessor :active_config

  def setup
    super

    dir = File.expand_path(File.dirname(__FILE__))
    test_dir = File.join(dir, 'active_config_test_multi')

    @active_config = ActiveConfig.new(:path => Dir[test_dir + '/*'])

    # Configure ActiveConfig to use our test config files.
    Object.const_set(:RAILS_ENV, 'development')
    ENV.delete('ACTIVE_CONFIG_OVERLAY') # Avoid gb magic.

    active_config._flush_cache
    active_config._verbose = nil # default
    active_config.reload(true)
    active_config._reload_disabled = nil # default
    active_config._reload_delay = nil # default
  end

  def teardown
    Object.send(:remove_const, :RAILS_ENV)
  end

  def test_multi
    assert_equal "WIN",  active_config.test.default
  end

end

#!/usr/bin/env ruby

# even if a gem is installed, load cnu_config and active_config locally
dir = File.dirname __FILE__
$LOAD_PATH.unshift File.join(dir, "..", "lib")

# Configure ActiveConfig to use our test config files.

# Test environment.
require 'rubygems'

# Test target
require 'active_config'

# Test dependencies
require 'test/unit'

class ActiveConfig::TestCollision < Test::Unit::TestCase

  def setup
    ENV.delete('ACTIVE_CONFIG_OVERLAY') # Avoid gb magic.
    ENV['ACTIVE_CONFIG_PATH'] = [File.expand_path("../active_config_test_collision/patha",__FILE__), File.expand_path("../active_config_test_collision/pathb",__FILE__)].join(':')
    Object.const_set(:RAILS_ENV, 'development')
    super
  end

  def teardown
    ENV.delete('ACTIVE_CONFIG_PATH')
    Object.send(:remove_const, :RAILS_ENV)
    super
  end

  def test_collision
    assert_raise ActiveConfig::DuplicateConfig do
      ActiveConfig.new
    end
  end

end

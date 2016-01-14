#!/usr/bin/env ruby
#$:.unshift File.expand_path("../../lib",__FILE__)

# even if a gem is installed, load cnu_config and active_config locally
dir = File.dirname __FILE__
$LOAD_PATH.unshift File.join(dir, "..", "lib")

# Configure ActiveConfig to use our test config files.
self.class.send(:remove_const, :RAILS_ENV) if defined?(RAILS_ENV) # avoid warning
RAILS_ENV = 'development'
ENV.delete('ACTIVE_CONFIG_OVERLAY') # Avoid gb magic.

# Test environment.
require 'rubygems'

# Test target
require 'active_config'

# Test dependencies
require 'test/unit'

class ActiveConfig::TestCollision < Test::Unit::TestCase

  def setup
    ENV['ACTIVE_CONFIG_PATH'] = [File.expand_path("../active_config_test_collision/patha",__FILE__), File.expand_path("../active_config_test_collision/pathb",__FILE__)].join(':')
    super
  end

  def test_collision
    assert_raise ActiveConfig::DuplicateConfig do
      ActiveConfig.new
    end
  end

  def teardown
    ENV.delete('ACTIVE_CONFIG_PATH')
    super
  end

end

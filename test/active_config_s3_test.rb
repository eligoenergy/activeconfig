require 'active_config'
require 'test/unit'

# s3 mocks:
# - connection is mocked
# - this works as if load.yml exists with the "value: 100" contents
class AWS::S3::Base
  def self.establish_connection!(options)
    raise "S3 connection error" unless options[:access_key_id] and options[:secret_access_key]
  end
end

class ActiveConfig::S3ConfigObject

  class FakeObject
    def metadata
    { :mtime => Time.utc(2013, 1, 1, 0, 0, 0) }
    end
  end

  def self.exists?(key)
    key == "file.yml" ? true : false
  end

  def self.value(key)
    raise "Key doesn't exist" unless key == "file.yml"
    "value: 100\n"
  end

  def self.find(key)
    raise "Key doesn't exist" unless key == "file.yml"
    FakeObject.new
  end

end

class ActiveConfigS3Test < Test::Unit::TestCase

  def active_config
    @active_config||= ActiveConfig.new s3: {
      bucket: "test",
      aws_access_key_id: "test",
      aws_secret_access_key: "test"
    }
  end

  def test_basic
    assert_equal 100, active_config.file.value
  end

  def test_wrong_config
    assert_raise(ActiveConfig::Error) { ActiveConfig.new(s3: {}) }
  end

end

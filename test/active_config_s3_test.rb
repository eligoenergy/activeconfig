require 'active_config'
require 'test/unit'
require 'fog'

# s3 mocks:
# - connection is mocked
# - this works as if load.yml exists with the "value: 100" contents
class ActiveConfigS3Test < Test::Unit::TestCase

  def setup
    Fog.mock!
    storage = Fog::Storage.new(provider: 'AWS', aws_access_key_id: "test", aws_secret_access_key: "test")
    dir = storage.directories.create(key: 'test')
    dir.files.create(key:'test_config.yml', body:'value: 100')
    @active_config = ActiveConfig.new s3: {
      bucket: "test",
      aws_access_key_id: "test",
      aws_secret_access_key: "test"
    }

  end

  def test_basic
    assert_equal 100, @active_config.test_config.value
  end

  def test_wrong_config
    assert_raise(ActiveConfig::Error) { ActiveConfig.new(s3: {}) }
  end

end

require 'active_config'
require 'test/unit'
require 'fog-aws'

# s3 mocks:
# - connection is mocked
# - this works as if load.yml exists with the "value: 100" contents
class ActiveConfigS3Test < Test::Unit::TestCase

  def setup
    Fog.mock!
    storage = Fog::Storage.new(provider: 'AWS', aws_access_key_id: "test", aws_secret_access_key: "test")
    dir = storage.directories.create(key: 'test')
    @config_file = dir.files.create(key:'test_config.yml', body:'value: 100')
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

  def test_config_rereads_changed_files
    @active_config._reload_delay = 1
    assert_equal 100, @active_config.test_config.value

    # change file without changing its mtime
    @config_file.body = 'value: 150'
    @config_file.save
    # file is not reread
    sleep(2)
    assert_equal 100, @active_config.test_config.value

    # change file, change mtime
    Fog::Time.now = ::Time.now + 1
    @config_file.body = 'value: 200'
    @config_file.save
    # file is reread automatically
    sleep(2)
    assert_equal 200, @active_config.test_config.value
  end

end

require 'socket'
require 'yaml'
require 'active_config/hash_weave' # Hash#weave
require 'rubygems'
require 'active_config/hash_config'
require 'active_config/suffixes'
require 'erb'

##
# See LICENSE.txt for details
#
#=ActiveConfig
#
# * Provides dottable, hash, array, and argument access to YAML 
#   configuration files
# * Implements multilevel caching to reduce disk accesses
# * Overlays multiple configuration files in an intelligent manner
#
# Config file access example:
#  Given a configuration file named test.yaml and test_local.yaml
#  test.yaml:
# ...
# hash_1:
#   foo: "foo"
#   bar: "bar"
#   bok: "bok"

# ...
# test_local.yaml:
# ...
# hash_1:
#   foo: "foo"
#   bar: "baz"
#   zzz: "zzz"
# ...
#
#  irb> ActiveConfig.test
#  => {"array_1"=>["a", "b", "c", "d"], "perform_caching"=>true,
#  "default"=>"yo!", "lazy"=>true, "hash_1"=>{"zzz"=>"zzz", "foo"=>"foo",
#  "bok"=>"bok", "bar"=>"baz"}, "secure_login"=>true, "test_mode"=>true}
#
#  --Notice that the hash produced is the result of merging the above
#  config files in a particular order
#
#  The overlay order of the config files is defined by ActiveConfig._get_file_suffixes:
#  * nil
#  * _local
#  * _config
#  * _local_config
#  * _{environment} (.i.e _development)
#  * _{environment}_local (.i.e _development_local)
#  * _{hostname} (.i.e _whiskey)
#  * _{hostname}_config_local (.i.e _whiskey_config_local)
#
#  ------------------------------------------------------------------
#  irb> ActiveConfig.test_local
#  => {"hash_1"=>{"zzz"=>"zzz", "foo"=>"foo", "bar"=>"baz"}, "test_mode"=>true} 
#

class ActiveConfig
  class DuplicateConfig < Exception; end
  class Error < Exception; end
end

class ActiveConfig
  EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY
  def _suffixes
    @suffixes_obj
  end
  # ActiveConfig.new take options from a hash (or hash like) object.
  # Valid keys are:
  #   :path           :  Where it can find the config files, defaults to ENV['ACTIVE_CONFIG_PATH'], or RAILS_ROOT/etc.  :path is either 
  #   :file           :  Single file mode.  Only look for configuration in that one, presenting that file at top level
  #   :s3 = {
  #     :bucket
  #     :aws_access_key_id
  #     :aws_secret_access_key
  #   }
  #   :root_file      :  Defines the file that holds "top level" configs. (ie active_config.key).  Defaults to "global" if global exists, nil otherwise.
  #   :suffixes       :  Either a suffixes object, or an array of suffixes symbols with their priority.  See the ActiveConfig::Suffixes object
  #   :config_refresh :  How often we should check for update config files
  #
  #
  #FIXME TODO
  def initialize(opts={})
    opts = Hash[:path, opts] if opts.is_a?(Array) || opts.is_a?(String)

    # :path/:file/:s3 have higher priority then ENV variables
    if opts.include?(:path) || opts.include?(:file) || opts.include?(:s3) then
      @config_path = opts[:path]
      @config_file = opts[:file]
      @config_s3 = opts[:s3]
    else
      # default or infer :path through ENV or Rails obejct.
      # no ENV variable for :file
      @config_path=ENV['ACTIVE_CONFIG_PATH'] ||
        (defined?(Rails) ? Rails.root+'etc' : nil) ||
        (defined?(RAILS_ROOT) ? File.join(RAILS_ROOT,'etc') : nil)
    end

    # alexg: Damn, this is ugly
    if ActiveConfig::Suffixes===opts[:suffixes]
      @suffixes_obj = opts[:suffixes] 
    end
    @suffixes_obj ||= Suffixes.new self, opts[:suffixes]
    @suffixes_obj.ac_instance=self
    @config_refresh = 
      (opts.has_key?(:config_refresh) ? opts[:config_refresh].to_i : 300)
    @on_load = { }
    self._flush_cache
    dups_h=Hash.new{|h,e|h[e]=[]}
    self._config_path.map{|e|
      if File.exists?(e) and File.directory?(e)
        Dir[e + '/*'].map{|f|
          if File.file?(f)
            dups_h[File.basename(f)] << f
          end
        }
      else
        STDERR.puts "WARNING:  Active Config Path NOT FOUND #{e}" unless opts[:quiet]
      end
    }
    dups = dups_h.to_a.select{|k,v|v.size>=2}
    raise ActiveConfig::DuplicateConfig.new(dups.map{|e|"Duplicate file #{e.first} found in \n#{e.last.map{|el|"\t"+el}.join("\n")}"}.join("\n")) if dups.size>0

    # root_file only possible with :path.
    #
    # IMPORTANT: This check needs to be after we have suffixes.
    # _valid_file? barfs if suffixes are offset
    if @config_path then
      @root_file=opts[:root_file] || 
        (_valid_file?('global') ? 'global' : nil)
    end

    _check_config!

    if _config_s3
      connection ||= Fog::Storage.new({
        :provider                 => 'AWS',
        :aws_access_key_id        => _config_s3[:aws_access_key_id],
        :aws_secret_access_key    => _config_s3[:aws_secret_access_key]
      })
      @s3_bucket = connection.directories.find{ |x| x.key == _config_s3[:bucket]}
    end
  end

  def _check_config!
    _config_path.each do |path|
      unless File.directory? path
        raise Error.new "#{path} not valid config path" 
      end
    end
    if _config_file && !File.exists?(_config_file) then
      raise Error.new "#{_config_file} not valid config file"
    end
    if _config_s3 && (!_config_s3[:bucket] || !_config_s3[:aws_access_key_id] || !_config_s3[:aws_secret_access_key])
      raise Error.new "Must configure s3 :bucket, :aws_access_key_id and :aws_secret_access_key"
    end
    if _root_file
      raise "#{_root_file} root file not available"  unless
        _valid_file?(_root_file)
      raise "#{_root_file} root file not valid without :path" if
        _config_path.empty?
    end

    configured = [!_config_path.empty?, !!_config_file, !!_config_s3].select { |c| c }
    if configured.length > 1
      raise Error.new "Pick one of :path, :file or :s3"
    elsif configured.length == 0
      raise Error.new "Neither :path nor :file nor :s3 are configured.  Pick one"
    end
  end

  def _config_path
    return [] unless @config_path
    @config_path_ary ||=
      begin
        path = 
          case @config_path
          when String then
            @config_path.split(File::PATH_SEPARATOR).reject{ | x | x.empty? }
          when Array then
            @config_path
          else
            # alexg: Rails.env returns Pathname
            [@config_path]
          end
        path.map!{|x| x.freeze }.freeze
      end
  end

  def _root_file
    @root_file
  end

  def _config_file
    @config_file
  end

  def _config_s3
    @config_s3
  end

  # DON'T CALL THIS IN production.
  def _flush_cache *types
    if types.size == 0 or types.include? :hash
      @cache_hash = { }
      @hash_times = Hash.new(0)
    end
    if types.size == 0 or types.include? :file
      @file_times = Hash.new(0)
      @file_cache = { }
    end
    self
  end

  def _reload_disabled=(x)
    @reload_disabled = x.nil? ? false : x
  end

  def _reload_delay=(x)
    @config_refresh = x || 300
  end

  def _verbose=(x)
    @verbose = x.nil? ? false : x;
  end

  ##
  # Get each config file's yaml hash for the given config name, 
  # to be merged later. Files will only be loaded if they have 
  # not been loaded before or the files have changed within the 
  # last five minutes, or force is explicitly set to true.
  #
  # If file contains the comment:
  #
  #   # ACTIVE_CONFIG:ERB
  #
  # It will be run through ERb before YAML parsing
  # with the following object bound:
  #
  #   active_config.config_file => <<the name of the config.yml file>>
  #   active_config.config_directory => <<the directory of the config.yml>>
  #   active_config.config_name => <<the config name>>
  #   active_config.config_files => <<Array of config files to be parsed>>
  #
  def _load_config_files(name, force=false)
    now = Time.now

    # Get array of all the existing files file the config name.
    config_files = _config_files(name)
    
    #$stderr.puts config_files.inspect
    # Get all the data from all yaml files into as hashes
    _fire_on_load(name)
    hashes = config_files.collect do |f|
      filename=f
      val=nil
      mod_time=nil

      begin
      if _config_s3
        config_object = @s3_bucket.files.get(filename)
        next unless config_object
        next(@file_cache[filename]) unless (mod_time=config_object.last_modified) != @file_times[filename]
        val = config_object.body
      else
        next unless File.exists?(filename)
        next(@file_cache[filename]) unless (mod_time=File.stat(filename).mtime) != @file_times[filename]
        File.open( filename ) { | yf |
          val = yf.read
        }
      end
      # If file has a # ACTIVE_CONFIG:ERB comment,
      # Process it as an ERb first.
      if /^\s*#\s*ACTIVE_CONFIG\s*:\s*ERB/i.match(val)
        # Prepare a object visible from ERb to
        # allow basic substitutions into YAMLs.
        active_config = HashConfig.new({
          :config_file => filename,
          :config_directory => File.dirname(filename),
          :config_name => name,
          :config_files => config_files,
        })
        val = ERB.new(val).result(binding)
      end
      # Read file data as YAML.
      val = YAML::load(val)
      # STDERR.puts "ActiveConfig: loaded #{filename.inspect} => #{val.inspect}"
      (@config_file_loaded ||= { })[name] = config_files
      rescue Exception => e
        raise
      end
      @file_cache[filename]=val
      @file_times[filename]=mod_time
      @file_cache[filename]
    end
    hashes.compact
  end


  def get_config_file(name)
    # STDERR.puts "get_config_file(#{name.inspect})"
    name = name.to_s # if name.is_a?(Symbol)
    now = Time.now
    return @cache_hash[name.to_sym] if 
      (now.to_i - @hash_times[name.to_sym]  < @config_refresh) 
    # return cached if we have something cached and no reload_disabled flag
    return @cache_hash[name.to_sym] if @cache_hash[name.to_sym] and @reload_disabled
    # $stderr.puts "NOT USING CACHED AND RELOAD DISABLED" if @reload_disabled
    @cache_hash[name.to_sym]=begin
      x = _config_hash(name)
      @hash_times[name.to_sym]=now.to_i
      x
    end
  end

  # is name valid name to pass to with_file method
  def _valid_file?(name)
    @cache_valid ||= {}
    @cache_valid[name.to_sym] ||= !_config_files(name).empty?
  end

  ## 
  # Returns a list of all relavant config files as specified by the
  # suffixes object.  Expected to behave appropreately, when passed
  # _config_file (which would include the path).  In case name already
  # has .yml extension, suffix will be inserted between stem and extension.
  #
  # _config_files will do a reasonable thing if name is either
  # _config_file (from :file), with a full or relative path, or name
  # to be found in the _config_path (from :path).  Initialization code
  # ensures only one is provided.  If that code is removed, :file
  # behavior will be simular to :root_file. (TODO:  maybe merge 2 together)

  def _config_files(name, ext='.yml') 
    return [name.to_s] if File.exists?(name.to_s) && !File.directory?(name.to_s)

    basename = File.basename(name.to_s, ext) || nil
    dirname  = File.dirname(name.to_s)
    path_ary = if _config_s3
      ['']  # no dirs on s3, just one place where objects are stored
    elsif _config_path.empty?
      [dirname]
    else
      _config_path
    end

    _suffixes.for(basename, ext).inject([]) do |files, name_x|
      # for :path style configs
      path_ary.reverse.inject(files) do |files, dir|
        if _config_s3
          files << name_x if @s3_bucket.files.select { |f| f.key == name_x }.first
        else
          fn = File.join(dir, name_x)
          files << fn if File.exists? fn
        end
        files
      end
    end
  end

  def _config_hash(name)
    @cache_hash[name] =
      HashConfig._make_indifferent_and_freeze(
        _load_config_files(name).inject({ }) { | n, h | n.weave(h, false) })
  end


  ##
  # Register a callback when a config has been reloaded.
  #
  # The config :ANY will register a callback for any config file change.
  #
  # Example:
  #
  #   class MyClass 
  #     @my_config = { }
  #     ActiveConfig.on_load(:global) do 
  #       @my_config = { } 
  #     end
  #     def my_config
  #       @my_config ||= something_expensive_thing_on_config(ACTIVEConfig.global.foobar)
  #     end
  #   end
  #
  def on_load(*args, &blk)
    args << :ANY if args.empty?
    proc = blk.to_proc

    # Call proc on registration.
    proc.call()

    # Register callback proc.
    args.each do | name |
      name = name.to_s
      (@on_load[name] ||= [ ]) << proc
    end
  end

  # Do reload callbacks.
  def _fire_on_load(name)
    callbacks = 
      (@on_load['ANY'] || EMPTY_ARRAY) + 
      (@on_load[name.to_s] || EMPTY_ARRAY)
    callbacks.uniq!
    STDERR.puts "_fire_on_load(#{name.inspect}): callbacks = #{callbacks.inspect}" if @verbose && ! callbacks.empty?
    callbacks.each do | cb |
      cb.call()
    end
  end

  def _check_config_changed(iname=nil)
    iname=iname.nil? ?  @cache_hash.keys.dup : [*iname]
    ret=iname.map{ | name |
    # STDERR.puts "ActiveConfig: config changed? #{name.inspect} reload_disabled = #{@reload_disabled}" if @verbose
    if config_changed?(name) && ! @reload_disabled 
      STDERR.puts "ActiveConfig: config changed #{name.inspect}" if @verbose
      if @cache_hash[name]
        @cache_hash[name] = nil

        # force on_load triggers.
        name
      end
    end
    }.compact
    return nil if ret.empty?
    ret
  end

  def with_file(name, *args)
    # STDERR.puts "with_file(#{name.inspect}, #{args.inspect})"; result = 
    args.inject(get_config_file(name)) { | v, i | 
      # STDERR.puts "v = #{v.inspect}, i = #{i.inspect}"
      case v
      when Hash
        v[i.to_s]
      when Array
        i.is_a?(Integer) ? v[i] : nil
      else
        nil
      end
    }
    # STDERR.puts "with_file(#{name.inspect}, #{args.inspect}) => #{result.inspect}"; result
  end

  #If you are using this in production code, you fail.
  def reload(force = false)
    if force || ! @reload_disabled
      _flush_cache
    end
    nil
  end

  ## 
  # Disables any reloading of config,
  # executes &block, 
  # calls check_config_changed,
  # returns result of block
  #
  def disable_reload(&block)
    # This should increment @reload_disabled on entry, decrement on exit.
    # -- kurt 2007/06/12
    result = nil
    reload_disabled_save = @reload_disabled
    begin
      @reload_disabled = true
      result = yield
    ensure
      @reload_disabled = reload_disabled_save
      _check_config_changed unless @reload_disabled
    end
    result
  end

  ##
  # Gets a value from the global config file
  #
  def [](key, file=_root_file)
    with_file(file, key)
  end

  ##
  # Short-hand access to config file by its name.
  #
  # Example:
  #
  #   ActiveConfig.global(:foo) => ActiveConfig.with_file(:global).foo
  #   ActiveConfig.global.foo   => ActiveConfig.with_file(:global).foo
  #
  def method_missing(method, *args)
    ## return self[method.to_sym] if @opts[:one_file] 
    if method.to_s=~/^_(.*)/
      _flush_cache 
      return @suffixes.send($1, *args)
    elsif _valid_file?(method)
      value = with_file(method, *args)
      value
    elsif _root_file
      value = with_file(_root_file, method, *args)
      value
    elsif _config_file
      value = with_file(_config_file, method, *args)
      value
    else 
      super
    end
  end
end


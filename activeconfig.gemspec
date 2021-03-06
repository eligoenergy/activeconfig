Gem::Specification.new do |s|
  s.name = "activeconfig"
  s.version = "1.0.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")

  s.authors = ["Jeremy Lawler", "Mark Friedgan", "Alexander Dymo"]
  s.date = "2018-11-20"
  s.description = "An extremely flexible configuration system.\ns the ability for certain values to be \"overridden\" when conditions are met.\nr example, you could have your production API keys only get read when the Rails.env == \"production\""
  s.summary = "An extremely flexible configuration system"
  s.email = "jeremylawler@gmail.com"

  s.executables = ["active_config"]
  s.require_paths = ["lib"]

  s.add_dependency("rdoc")
  s.add_dependency("bundler")
end

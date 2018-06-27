source "http://rubygems.org"
ruby '2.3.6'

gemspec

gem 'fog-aws', '~> 2.0'
gem "mime-types" # Required by fog

group :development do
  gem "rake"
  gem "rdoc", "~> 3.12", require: false
  gem "bundler", "> 1.0.0"
  gem "guard", require: false
end

group :test do
  gem "test-unit"
end

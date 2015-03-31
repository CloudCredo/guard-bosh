unless ENV['NO_COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end
require 'guard/bosh'

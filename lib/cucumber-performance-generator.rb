require 'cliver'
require 'capybara/poltergeist'

require_relative 'cucumber-performance-generator/hooks.rb'
require_relative 'cucumber-performance-generator/functions.rb'
require_relative 'cucumber-performance-generator/poltergeist_override.rb'




options = {}

PHANTOMJS_VERSION = ['1.9.7']
PHANTOMJS_NAME    = 'phantomjs'
puts Cliver::detect!((options[:path] || PHANTOMJS_NAME), *PHANTOMJS_VERSION)

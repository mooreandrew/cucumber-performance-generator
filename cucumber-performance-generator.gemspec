Gem::Specification.new do |s|
  s.name        = 'cucumber-performance-generator'
  s.version     = '0.0.3'
  s.date        = '2014-09-27'
  s.summary     = ""
  s.description = "This gem adds to convert a capybara/poltergeist script into a load script usable by the cucumber-performance gem."
  s.authors     = ["Andrew Moore"]
  s.email       = 'mooreandrew@gmail.com'
  s.files       = Dir.glob('{lib}/**/*') + %w(LICENSE README.md)
  s.homepage    =
    'https://github.com/mooreandrew/cucumber-performance-generator'
  s.license       = 'MIT'
  s.add_dependency 'poltergeist', '>= 1.5.1'
  s.add_dependency 'cliver',           '~> 0.3.1'

end

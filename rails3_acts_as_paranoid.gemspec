# -*- encoding: utf-8 -*-
$:.push(File.expand_path('../lib', __FILE__))
require('rails3_acts_as_paranoid/version')

Gem::Specification.new do |s|
  s.name              = "rails3_acts_as_paranoid"
  s.version           = Rails3ActsAsParanoid::VERSION
  s.platform          = Gem::Platform::RUBY
  s.authors           = ["Goncalo Silva", "Philipp Ullmann"]
  s.email             = ["goncalossilva@gmail.com", "philipp.ullmann@create.at"]
  s.homepage          = "http://github.com/goncalossilva/rails3_acts_as_paranoid"
  s.summary           = "Active Record (>=3.0) plugin which allows you to hide and restore records without actually deleting them."
  s.description       = "Active Record (>=3.0) plugin which allows you to hide and restore records without actually deleting them. Check its GitHub page for more in-depth information."
  s.rubyforge_project = s.name + "_create"

  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_dependency "activerecord", "~> 3.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  
  s.add_development_dependency('rake', ['>= 0.9.0'])
  s.add_development_dependency('sqlite3-ruby', ['>= 1.3.0'])
  s.add_development_dependency('activesupport', ['>= 3.1.0'])
  s.add_development_dependency('rdoc', ['>= 3.9.0'])
end

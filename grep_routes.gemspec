# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
Gem::Specification.new do |s|
  s.name        = "grep_routes"
  s.version     = "0.0.3"
  s.authors     = ["Tyler Montgomery"]
  s.email       = ["tyler.a.montgomery@gmail.com"]
  s.homepage    = "http://github.com/ubermajestix/grep_routes"
  s.summary     = %q{Fast Routes for Rails}
  s.description = %q{Greppin in ur routes}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activesupport"  , "~> 3.1"
  s.add_dependency "actionpack"     , "~> 3.1"

  s.add_development_dependency "minitest", "~> 2.11.2"
end

spec = Gem::Specification.new do |s|
  s.name = 'gdash'
  s.version = "0.0.5"
  s.author = 'R.I.Pienaar'
  s.email = 'rip@devco.net'
  s.homepage = 'http://devco.net/'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Graphite Dashboard'
  s.description = "A simple dashboard for creating and displaying Graphite graphs"
  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.has_rdoc = false
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_dependency 'graphite_graph', "~>0.0.8"
  s.add_dependency 'sinatra'
  s.add_dependency 'redcarpet'
  s.add_dependency 'less'
  s.add_dependency 'therubyracer'
  s.add_dependency 'json'
end

spec = Gem::Specification.new do |s|
  s.name = 'gdash'
  s.version = "0.0.5"
  s.author = 'R.I.Pienaar'
  s.email = 'rip@devco.net'
  s.homepage = 'http://devco.net/'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Graphite Dashboard'
  s.description = "A simple dashboard for creating and displaying Graphite graphs"
# Add your other files here if you make them
  s.files = FileList["{README.md,COPYING,CONTRIBUTORS,bin,lib,public,views,sample,Gemfile,Gemfile.lock}/**/*"].to_a
  s.require_paths << 'lib'
  s.has_rdoc = false
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_dependency 'graphite_graph'
  s.add_dependency 'sinatra'
#  s.add_dependency 'redcarpet'
  s.add_dependency 'therubyrhino'
  s.executables=['lib/gdash.rb']
  s.default_executable = 'lib/gdash.rb'
end

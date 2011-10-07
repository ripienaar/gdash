$: << File.join(File.dirname(__FILE__), "lib")

require 'gdash'

set :run, false

# Local logging
#FileUtils.mkdir_p 'log' unless File.exists?('log')
#log = File.new('log/sinatra.log', 'a')
#$stdout.reopen(log)
#$stderr.reopen(log)

templatedir = File.join(File.dirname(__FILE__), "graph_templates")

run GDash::SinatraApp.new("http://unimatrix1.devco.net/", templatedir, "My Dashboard")

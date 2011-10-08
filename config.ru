$: << File.join(File.dirname(__FILE__), "lib")

require 'gdash'

set :run, false

# If you want basic HTTP authentication uncomment this and set a u/p
# use Rack::Auth::Basic do |username, password|
#   username == 'admin' && password == 'secret'
# end

templatedir = File.join(File.expand_path(File.dirname(__FILE__)), "graph_templates")

run GDash::SinatraApp.new("http://graphite.example.net/", templatedir, "My Dashboard")

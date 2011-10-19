$: << File.join(File.dirname(__FILE__), "lib")

require 'gdash'

set :run, false

config = YAML.load_file(File.expand_path("../config/gdash.yaml", __FILE__))

# If you want basic HTTP authentication
# include :username and :password in gdash.yaml
use Rack::Auth::Basic do |username, password|
  username == config[:username] && password == config[:password]
end if config[:username] && config[:password]

run GDash::SinatraApp.new(config[:graphite], config[:templatedir], config[:options])

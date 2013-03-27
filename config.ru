$: << File.join(File.dirname(__FILE__), "lib")

#require 'bundler/setup'
require 'gdash'
if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
 require 'java'
 configfile = java.lang.System.getProperty "config"
 puts "configfile: #{configfile}"
 if configfile.nil?
   raise "No configuration defined. Usage: java -Dconfig=<absolutepath>/gdash.yaml -jar gdash.war"
 else
  config = YAML.load_file(File.expand_path(configfile, __FILE__))

end

else
 config = YAML.load_file(File.expand_path("../config/gdash.yaml", __FILE__))
end

set :run, false


# If you want basic HTTP authentication
# include :username and :password in gdash.yaml
if config[:username] && config[:password]
  use Rack::Auth::Basic do |username, password|
    username == config[:username] && password == config[:password]
  end
end

run GDash::SinatraApp.new(config[:graphite], config[:templatedir], config[:options])

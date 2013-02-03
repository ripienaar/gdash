Warbler::Config.new do |config|
  config.dirs = %w(lib config public views)
  config.includes = FileList["config.ru"]
  config.gem_dependencies = true
  config.webserver = 'jetty'
end

require 'rake/clean'
require 'rubygems'
require 'rubygems/package_task'

spec = eval(File.read('gdash.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
end

require 'warbler'
Warbler::Task.new

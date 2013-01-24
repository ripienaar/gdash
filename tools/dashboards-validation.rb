#!/usr/bin/env ruby

require 'optparse'
require 'gdash'
require 'gdash/dashboard'

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: " + opt.program_name + " [OPTIONS]"

  opt.on("-p", "--path PATH", String, "dashboard path") do |path|
    options[:path] = path
  end

  opt.on("-h","--help","help") do
    puts opt_parser
  end
end

begin
  opt_parser.parse!
  if options[:path].nil?
    puts "Missing options path."
    puts opt_parser
    abort()
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts opt_parser
  abort()
end

unless File.directory? options[:path]
  puts "Path #{options[:path]} does not exists."
  puts opt_parser
  abort()
end

errors = []

Dir.foreach(options[:path]).each do |dashboard|
  next if dashboard == '.' or dashboard == '..'
  begin
    graph_directory = File.join(options[:path], dashboard)

    Dir.foreach(graph_directory).each do |category|
      next if category == '.' or category == '..'
      category_dir = File.join(graph_directory, category)
      category_desc = File.join(category_dir, 'dash.yaml')

      if !File.exists?(category_desc)
        errors << "The dashboard description file (" + category_desc + ") is missing."
      end

      graphs = Dir.entries(category_dir).select{|f| f.match(/\.graph$/)}
      for graph in graphs
        begin
          full_path = File.join(category_dir, graph)
          GraphiteGraph.new(full_path)
        rescue Exception => e
          errors << "Can't parse the graph file " + full_path + ":"
          errors << "\t " + e.message
        end
      end
    end
  rescue Exception => e
    p e
  end
end

if !errors.empty?
  abort(errors.join("\n"))
end

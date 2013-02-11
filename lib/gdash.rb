require 'rubygems'
require 'sinatra'
require 'yaml'
require 'erb'
require 'redcarpet'
require 'less'

class GDash
  require 'gdash/dashboard'
  require 'gdash/monkey_patches'
  require 'gdash/sinatra_app'
  require 'graphite_graph'

  attr_reader :graphite_base, :graphite_render, :graph_templates, :category, :dash_templates, :height, :width, :from, :until

  def initialize(graphite_base, render_url, graph_templates, category,  options={})
    @graphite_base = graphite_base
    @graphite_render = [@graphite_base, "/render/"].join
    @graph_templates = graph_templates
    @category = category
    @dash_templates = File.join(graph_templates, category)
    @height = options.delete(:height)
    @width = options.delete(:width)
    @from = options.delete(:from)
    @until = options.delete(:until)

    raise "Dashboard templates directory #{@dash_templates} does not exist" unless File.directory?(@dash_templates)
  end

  def dashboard(name, options={})
    options[:width] ||= @width
    options[:height] ||= @height
    options[:from] ||= @from
    options[:until] ||= @until


    Dashboard.new(name, graph_templates, category, options, graphite_render)
  end

  def list
    dashboards.map {|dash| dash[:link]}
  end

  def dashboards
    dashboards = []

    Dir.entries(dash_templates).each do |dash|
      begin
        yaml_file = File.join(dash_templates, dash, "dash.yaml")
        if File.exist?(yaml_file)
          dashboards << YAML.load_file(yaml_file).merge({:link => dash})
        end
      rescue Exception => e
        p e
      end
    end

    dashboards.sort_by{|d| d[:name].to_s}
  end
end

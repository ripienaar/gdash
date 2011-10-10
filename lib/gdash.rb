require 'rubygems'
require 'sinatra'
require 'yaml'
require 'erb'

class GDash
    require 'gdash/dashboard'
    require 'gdash/monkey_patches'
    require 'gdash/sinatra_app'
    require 'graphite_graph'

    attr_reader :graphite_base, :graphite_render, :dash_templates, :height, :width

    def initialize(graphite_base, render_url, dash_templates, width=500, height=250)
        @graphite_base = graphite_base
        @graphite_render = [@graphite_base, "/render/"].join
        @dash_templates = dash_templates
        @height = height
        @width = width

        raise "Dashboard templates directory #{@dash_templates} does not exist" unless File.directory?(@dash_templates)
    end

    def dashboard(name, width=nil, height=nil)
        width ||= @width
        height ||= @height

        Dashboard.new(name, dash_templates, width, height)
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

        dashboards.sort_by{|d| d[:name]}
    end
end

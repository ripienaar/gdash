require 'rubygems'
require 'sinatra'
require 'yaml'
require 'erb'

class GDash
    require 'gdash/dashboard'
    require 'gdash/monkey_patches'
    require 'gdash/sinatra_app'
    require 'graphite_graph'

    attr_reader :graphite_base, :graphite_render, :dash_templates, :height, :width, :from, :untiltime

    def initialize(graphite_base, render_url, dash_templates, width=500, height=250, from="-1hour", untiltime="now")
        @graphite_base = graphite_base
        @graphite_render = [@graphite_base, "/render/"].join
        @dash_templates = dash_templates
        @height = height
        @width = width
        @from = from
        @untiltime = untiltime

        raise "Dashboard templates directory #{@dash_templates} does not exist" unless File.directory?(@dash_templates)
    end

    def dashboard(name, width=nil, height=nil, from=nil, untiltime=nil)
        width ||= @width
        height ||= @height
        from ||= @from
        untiltime ||= @untiltime

        Dashboard.new(name, dash_templates, width, height, from, untiltime)
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

require 'json'

class GDash
  class SinatraApp < ::Sinatra::Base
    def initialize(graphite_base, graph_templates, options = {})
      # where the whisper data is
      @whisper_dir = options.delete(:whisper_dir) || "/var/lib/carbon/whisper"

      # where graphite lives
      @graphite_base = graphite_base

      # where the graphite renderer is
      @graphite_render = [@graphite_base, "/render/"].join

      # where to find graph, dash etc templates
      @graph_templates = graph_templates

      # the dash site might have a prefix for its css etc
      @prefix = options.delete(:prefix) || ""

      # the page refresh rate
      @refresh_rate = options.delete(:refresh_rate) || 60

      # how many columns of graphs do you want on a page
      @graph_columns = options.delete(:graph_columns) || 2

      # how wide each graph should be
      @graph_width = options.delete(:graph_width)

      # how hight each graph sould be
      @graph_height = options.delete(:graph_height)

      # Dashboard title
      @dash_title = options.delete(:title) || "Graphite Dashboard"

      # Time filters in interface
      @interval_filters = options.delete(:interval_filters) || Array.new

      @intervals = options.delete(:intervals) || []

      @top_level = Hash.new
      Dir.entries(@graph_templates).each do |category|
        if File.directory?("#{@graph_templates}/#{category}")
          unless ("#{category}" =~ /^\./ )
            @top_level["#{category}"] = GDash.new(@graphite_base, "/render/", File.join(@graph_templates, "/#{category}"), {:width => @graph_width, :height => @graph_height})
          end
        end
      end

      super()
    end

    set :static, true
    set :views, File.join(File.expand_path(File.dirname(__FILE__)), "../..", "views")
    if Sinatra.const_defined?("VERSION") && Gem::Version.new(Sinatra::VERSION) >= Gem::Version.new("1.3.0")
      set :public_folder, File.join(File.expand_path(File.dirname(__FILE__)), "../..", "public")
    else
      set :public, File.join(File.expand_path(File.dirname(__FILE__)), "../..", "public")
    end

    get '/' do
      if @top_level.empty?
        @error = "No dashboards found in the templates directory"
      end

      erb :index
    end

    Less.paths << File.join(settings.views, 'bootstrap')
    get "/bootstrap/:name.css" do
      less :"bootstrap/#{params[:name]}", :paths => ["views/bootstrap"]
    end

    get '/:category/:dash/details/:name' do
      if @top_level["#{params[:category]}"].list.include?(params[:dash])
        @dashboard = @top_level[@params[:category]].dashboard(params[:dash])
      else
        @error = "No dashboard called #{params[:dash]} found in #{params[:category]}/#{@top_level[params[:category]].list.join ','}."
      end

      if @intervals.empty?
        @error = "No intervals defined in configuration"
      end

      if main_graph = @dashboard.graph_by_name(params[:name])
        @graphs = @intervals.map do |e|
          new_props = {:from => e[0], :title => "#{main_graph[:graphite].properties[:title]} - #{e[1]}"}
          new_props = main_graph[:graphite].properties.merge new_props
          graph = main_graph.dup
          graph[:graphite] = GraphiteGraph.new(main_graph[:graphite].file, new_props)
          graph
        end
      else
        @error = "No such graph available"
      end

      erb :detailed_dashboard
    end

    get '/:category/:dash/full/?*' do
      options = {}
      params["splat"] = params["splat"].first.split("/")

      params["columns"] = params["splat"][0].to_i || @graph_columns

      if params["splat"].size == 3
        options[:width] = params["splat"][1].to_i
        options[:height] = params["splat"][2].to_i
      else
        options[:width] = @graph_width
        options[:height] = @graph_height
      end

      options.merge!(query_params)

      if @top_level["#{params[:category]}"].list.include?(params[:dash])
        @dashboard = @top_level[@params[:category]].dashboard(params[:dash], options)
      else
        @error = "No dashboard called #{params[:dash]} found in #{params[:category]}/#{@top_level[params[:category]].list.join ','}"
      end

      erb :full_size_dashboard, :layout => false
    end

    get '/:category/:dash/?*' do

      options = {}
      params["splat"] = params["splat"].first.split("/")

      t_from = t_until = nil
      if request.cookies["date"]
        cookie_date = JSON.parse(request.cookies["date"], {:symbolize_names => true})
        t_from = params[:from] || cookie_date[:from]
        t_until = params[:until] || cookie_date[:until]
      end

      case params["splat"][0]
        when 'time'
          t_from = params["splat"][1] || t_from || "-1hour"
          t_until = params["splat"][2] || t_until || "now"
        end

      options[:from] = t_from
      options[:until] = t_until

      response.set_cookie('date',
        :expires => Time.now + 60 * 60 * 24 * 14,
        :path => "/",
        :value => { "from" => t_from, "until" => t_until }.to_json
      )

      options.merge!(query_params)

      if @top_level["#{params[:category]}"].list.include?(params[:dash])
        @dashboard = @top_level[@params[:category]].dashboard(params[:dash], options)
      else
        @error = "No dashboard called #{params[:dash]} found in #{params[:category]}/#{@top_level[params[:category]].list.join ','}."
      end

      erb :dashboard
    end

    get '/docs/' do
      markdown :README, :layout_engine => :erb
    end

    helpers do
      include Rack::Utils

      alias_method :h, :escape_html

      def link_to_interval(options)
        "<a href=\"#{ [@prefix, params[:category], params[:dash], 'time', h(options[:from]), h(options[:to])].join('/') }\">#{ h(options[:label]) }</a>"
      end

      def query_params
        hash = {}
        protected_keys = [:category, :dash, :splat]

        params.each do |k, v|
          hash[k.to_sym] = v unless protected_keys.include?(k.to_sym)
        end

        hash
      end

      def fmt_for_select_date(date, default)
        result = ""
        if date.nil? 
          result = default
        else 
          result = DateTime.parse(date).strftime("%Y-%m-%d %H:%M")
        end
        return result
      end
    end
  end
end

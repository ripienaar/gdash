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
            gdash = GDash.new(@graphite_base, "/render/", @graph_templates, category, {:width => @graph_width, :height => @graph_height})
            @top_level["#{category}"] = gdash unless gdash.dashboards.empty?
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

    get '/:category/:dash/details/:name' do
      options = {}
      if query_params[:print]
        options[:include_properties] = "print.yml"
        options[:graph_properties] = { 
		:background_color => "white",
		:foreground_color => "black"
	}
      end
      options.merge!(query_params)

      if @top_level["#{params[:category]}"].list.include?(params[:dash])
        @dashboard = @top_level[@params[:category]].dashboard(params[:dash], options)
      else
        @error = "No dashboard called #{params[:dash]} found in #{params[:category]}/#{@top_level[params[:category]].list.join ','}."
      end

      if @intervals.empty?
        @error = "No intervals defined in configuration"
      end

      if main_graph = @dashboard.graphs[params[:name].to_i][:graphite]
        @graphs = @intervals.map do |e|
          new_props = {:from => e[0], :title => "#{main_graph.properties[:title]} - #{e[1]}"}
          new_props = main_graph.properties.merge new_props
          GraphiteGraph.new(main_graph.file, new_props)
        end
      else
        @error = "No such graph available"
      end

      if !query_params[:print]
	erb :detailed_dashboard
      else
	erb :print_detailed_dashboard, :layout => false
      end
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

      case params["splat"][0]
        when 'time'
          options[:from] = params["splat"][1]
          options[:until] = params["splat"][2]
        end

      if query_params[:print]
        options[:include_properties] = "print.yml"
        options[:graph_properties] = { 
		:background_color => "white",
		:foreground_color => "black"
	}
      end
      options.merge!(query_params)

      options[:from] ||= "-1hour"
      options[:until] ||= "now"

      if @top_level["#{params[:category]}"].list.include?(params[:dash])
        @dashboard = @top_level[@params[:category]].dashboard(params[:dash], options)
      else
        @error = "No dashboard called #{params[:dash]} found in #{params[:category]}/#{@top_level[params[:category]].list.join ','}."
      end

      if !query_params[:print]
	erb :dashboard
      else
	erb :print_dashboard, :layout => false
      end
    end

    get '/docs/' do
      markdown :README, :layout_engine => :erb
    end

    helpers do
      include Rack::Utils

      alias_method :h, :escape_html
      alias_method :u, :escape

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

      def link_to_print
	uri =  URI.parse(request.path)
	new_query_ar = URI.decode_www_form(request.query_string) << ["print", "1"]
	uri.query = URI.encode_www_form(new_query_ar)
	uri.to_s
      end
    end
  end
end

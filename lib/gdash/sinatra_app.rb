require 'cgi'
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
            gdash = GDash.new(@graphite_base, "/render/", @graph_templates, category, {:width => @graph_width, :height => @graph_height})
            @top_level["#{category}"] = gdash unless gdash.dashboards.empty?
          end
        end
      end

      super()
    end

    before do

      # To build a list for Typeahead Search
      @search_elements = []
      @top_level.keys.each do |dash|
        @top_level[dash].dashboards.each { |d| @search_elements << "#{d[:category]}/#{d[:name]}"}
      end

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

      mapper = []
      @top_level.keys.each do |k|
        @top_level[k].dashboards.each do |d|
          mapper << d #"#{k}/#{d[:name]}"
        end
      end

      @dashboard_to_display = mapper.group_by {|d| d[:category]} 

      erb :index
    end

    get '/monitoring_export' do
      content_type :json
      return_data = []
      @top_level.keys.each do |category|
        @top_level[category].dashboards.each do |dashboard_name|
          Dashboard.new(dashboard_name[:link], @graph_templates, dashboard_name[:category], {}, @graphite_render).graphs.each do |graph|
            graph_object = graph[:graphite]
            if graph_object.warning_threshold.any? or graph_object.critical_threshold.any?
              return_data << {
                :graphite_url => [@graphite_render, "?", graph_object.url].join,
                :warning => graph_object.warning_threshold,
                :critical => graph_object.critical_threshold,
                :graph_properties => graph_object.properties
              }
            end
          end
        end
      end
      return_data.to_json
    end

    get '/search?*' do
      search_string = params['dashboard'] || '' 
      d1,d2 = search_string.split('/', 2)
      if d2
        category, dashboard = d1, d2
      else
        category, dashboard = nil, d1
      end
      
      mapper = []
      @top_level.keys.each do |k|
        @top_level[k].dashboards.each do |d|
          mapper << d #"#{k}/#{d[:name]}"
        end
      end
  
      result = mapper.select {|d| d[:name] == dashboard && (category == nil || d[:category] == category )}

      if result.count == 1
        redirect "#{@prefix}/#{result[0][:category]}/#{result[0][:link]}"
      elsif result.count == 0 then
        @error = "No dashboards found in the templates directory, Search = <b>'#{search_string}'</b>"
        @dashboard_to_display = mapper.group_by {|d| d[:category]} 
        erb :index 
      else 
        @dashboard_to_display = result.group_by {|d| d[:category]} 
        erb :index 
      end
    end

    Less.paths << File.join(settings.views, 'bootstrap')
    get "/bootstrap/:name.css" do
      less :"bootstrap/#{params[:name]}", :paths => ["views/bootstrap"]
    end

    get '/:category/:dash/details/:name/?*' do
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
        @dashboard = @top_level[@params[:category]].dashboard(params[:dash],options)
      else
        @error = "No dashboard called #{params[:dash]} found in #{params[:category]}/#{@top_level[params[:category]].list.join ','}."
      end

      if @intervals.empty?
        @error = "No intervals defined in configuration"
      end

      if main_graph = @dashboard.graph_by_name(params[:name], options)
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

      if !query_params[:print]
        erb :detailed_dashboard
      else
        erb :print_detailed_dashboard, :layout => false
      end
    end

    get '/:category/:dash/full/?*' do
      options = {}
      params["splat"] = params["splat"].first.split("/")

      @graph_columns = params["splat"][0].to_i unless params["splat"][0].nil?

      if params["splat"].size == 3
        options[:width] = params["splat"][1].to_i
        options[:height] = params["splat"][2].to_i
      else
        options[:width] = @graph_width
        options[:height] = @graph_height
      end

      options[:from] = params[:from] if params[:from]
      options[:until] = params[:until] if params[:until]

      if @top_level["#{params[:category]}"].list.include?(params[:dash])
        @dashboard = @top_level[@params[:category]].dashboard(params[:dash], options)
      else
        @error = "No dashboard called #{params[:dash]} found in #{params[:category]}/#{@top_level[params[:category]].list.join ','}"
      end
      options.merge!(query_params)

      @graphs = @dashboard.graphs(options)

      erb :full_size_dashboard, :layout => false
    end

    get '/:category/:dash/?*' do

      options = {}
      params["splat"] = params["splat"].first.split("/")

      t_from = t_until = nil
      if request.cookies["interval"]
        cookie_date = JSON.parse(request.cookies["interval"], {:symbolize_names => true})
        t_from = params[:from] || cookie_date[:from]
        t_until = params[:until] || cookie_date[:until]
      end

      case params["splat"][0]
      when 'time'
        t_from = params["splat"][1] || "-1hour"
        t_until = params["splat"][2] || "now"
      when nil
        redirect uri_to_interval({:from => t_from, :to => t_until}) if t_from 
      end

      options[:from] = t_from
      options[:until] = t_until

      response.set_cookie('interval',
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

      @graphs = @dashboard.graphs(options)

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

      def query_params
        hash = {}
        protected_keys = [:category, :dash, :splat, :details, :name]

        params.each do |k, v|
          k = query_alias_map(k)
          v = v.inject({}) { |memo, e| memo[e[0].to_sym] = e[1]; memo } if v.is_a?(Hash)
          hash[k.to_sym] = v unless protected_keys.include?(k.to_sym)
        end

        hash
      end

      def query_alias_map(k)
        q_aliases = {'p' => 'placeholders'}
        q_aliases[k] || k
      end

      def query_params_encode(query_params) 
        query_params.map{ |k,v|
          # Must support multivalue
          if v.is_a? Array  
            v.map{ |v2| [k.to_s,CGI.escape(v2)].join('=') }.join('&')
          else
            [k.to_s,CGI.escape(v)].join('=')
          end  
        }.join('&')
      end

      def uri_to_interval(options)
        uri = URI([@prefix, params[:category], params[:dash], 'time', h(options[:from]), h(options[:to])].join('/'))
        uri.query = request.query_string unless request.query_string.empty? 
        uri.to_s        
      end

      def link_to_interval(options)
        "<a href=\"#{ uri_to_interval(options) }\">#{ h(options[:label]) }</a>"
      end

      def uri_to_print
        uri = URI.parse(request.path)
        new_query_ar = CGI.parse(request.query_string).merge! "print" => "1"
        uri.query = query_params_encode(new_query_ar)
        uri.to_s
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

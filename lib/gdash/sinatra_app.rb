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

            # how many columns of graphs do you want on a page
            @graph_columns = options.delete(:graph_columns) || 2

            # how wide each graph should be
            @graph_width = options.delete(:graph_width) || 500

            # how hight each graph sould be
            @graph_height = options.delete(:graph_height) || 250

            # Dashboard title
            @dash_title = options.delete(:title) || "Graphite Dashboard"

            @dash_site = GDash.new(@graphite_base, "/render/", File.join(@graph_templates, "/dashboards"), @graph_width, @graph_height)

            super()
        end

        set :static, true
        set :views, File.join(File.expand_path(File.dirname(__FILE__)), "../..", "views")
        set :public_folder, File.join(File.expand_path(File.dirname(__FILE__)), "../..", "public")

        get '/' do
            if @dash_site.list.empty?
                @error = "No dashboards found in the templates directory"
            end

            erb :index
        end

	get '/dashboard/:dash/full/?*' do
            params["splat"] = params["splat"].first.split("/")

            params["columns"] = params["splat"][0].to_i || @graph_columns

            if params["splat"].size == 3
                width = params["splat"][1].to_i
                height = params["splat"][2].to_i
            else
                width = @graph_width
                height = @graph_height
            end


            if @dash_site.list.include?(params[:dash])
                @dashboard = @dash_site.dashboard(params[:dash], width, height)
            else
                @error = "No dashboard called #{params[:dash]} found in #{@dash_site.list.join ','}"
            end

            erb :full_size_dashboard, :layout => false
	end

        get '/dashboard/:dash/' do
            if @dash_site.list.include?(params[:dash])
                @dashboard = @dash_site.dashboard(params[:dash])
            else
                @error = "No dashboard called #{params[:dash]} found in #{@dash_site.list.join ','}"
            end

            erb :dashboard
        end

        helpers do
            include Rack::Utils

            alias_method :h, :escape_html
        end
    end
end

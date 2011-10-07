class GDash
    class SinatraApp < ::Sinatra::Base
        def initialize(graphite_base, graph_templates, title="Graphite Dashboard", prefix="", graph_columns=2, graph_width=500, graph_height=250, whisper_dir="/var/lib/carbon/whisper")
            # where the whisper data is
            @whisper_dir = whisper_dir

            # where graphite lives
            @graphite_base = graphite_base

            # where the graphite renderer is
            @graphite_render = [@graphite_base, "/render/"].join

            # where to find graph, dash etc templates
            @graph_templates = graph_templates

            # the dash site might have a prefix for its css etc
            @prefix = prefix

            # how many columns of graphs do you want on a page
            @graph_columns = graph_columns

            # how wide each graph should be
            @graph_width = graph_width

            # how hight each graph sould be
            @graph_height = graph_height

            # Dashboard title
            @dash_title = title

            @dash_site = GDash.new(@graphite_base, "/render/", File.join(@graph_templates, "/dashboards"), @graph_width, @graph_height)

            super()
        end

        set :static, true
        set :public, "public"

        get '/' do
            erb :index
        end

        get '/dashboard/:dash' do
            if @dash_site.list.include?(params[:dash])
                @dashboard = @dash_site.dashboard(params[:dash])

                erb :dashboard
            else
                @error = "No dashboard called #{params[:dash]} found in #{@dash_site.dashboards.join ','}"
                erb :dashboard
            end
        end

        helpers do
            include Rack::Utils

            alias_method :h, :escape_html
        end
    end
end

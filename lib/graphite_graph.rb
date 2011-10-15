#    title          "this is a title"
#    vtitle         "v label"
#    width          100
#    height         100
#    from           "-2days"
#    area           :none
#    description
#
#    field  :foo, :data => "some.data.item",
#                 :derivative => false,
#                 :dashed => true,
#                 :color => "yellow"
#
#    service :munin, :cpu do
#      # this takes <host>.munin.cpu.idle
#      field :idle, :derivative => true,
#                   :scale => 0.001,
#                   :dashed => true,
#                   :color => "blue"
#    end
#
#    # this is for arbitrary data anywhere
#    field :deploys, :target => "drawAsInfinite(site.deploys)", :color => "red"
#
# result is an array of graph object with a lot of field hashes and a to_url
# method that makes the img src url
#
# Since graphite 0.9.9 you can create Holt-Winters Forecast graphs using a simple
# helper:
#
# hw_predict  :foo, :data => "sumSeries(tc*.site.users.male)",
#                   :alias => "Male",
#                   :derivative => false,
#                   :color => "yellow"
#
# This creates 3 data fields - 1 the actual data, 1 forecast and the confidence
# bands, an example can be seen in samples
class GraphiteGraph
    attr_reader :info, :properties, :targets, :target_order

    def initialize(file, overrides={}, info={})
        @info = info
        @file = file
        @munin_mode = false
        @overrides = overrides

        load_graph
    end

    def defaults
        @properties = {:title => "",
                       :vtitle => "",
                       :width => 500,
                       :height => 250,
                       :from => "-1hour",
                       :surpress => false,
                       :description => nil,
                       :area => :none}.merge(@overrides)

    end

    def [](key)
        if key == :url
            url
        else
            @properties[key]
        end
    end

    def method_missing(meth, *args)
        if properties.include?(meth)
            properties[meth] = args.first unless @overrides.include?(meth)
        else
            super
        end
    end

    def load_graph
        @properties = defaults
        @targets = {}
        @target_order = []

        self.instance_eval(File.read(@file))
    end

    def service(service, data, &blk)
        raise "No hostname given for this instance" unless info[:hostname]

        @service_mode = {:service => service, :data => data}

        blk.call

        @service_mode = false
    end

    # add 2 fields using the Holt-Winters Confidence Band prediction model
    #
    #    hw_predict  :foo, :data => "some.data.item",
    #                      :derivative => false,
    #                      :color => "yellow"
    #
    def hw_predict(name, args)
        raise ":data is needed as an argument to a Holt-Winters Confidence forecast" unless args[:data]

        forecast_args = args.clone
        bands_args = args.clone

        forecast_args[:data] = "holtWintersForecast(#{forecast_args[:data]})"
        forecast_args[:alias] = "#{args[:alias]} Forecast"
        forecast_args[:color] = "blue"
        field "#{name}_forecast", forecast_args

        bands_args[:data] = "holtWintersConfidenceBands(#{bands_args[:data]})"
        bands_args[:color] = "grey"
        bands_args[:dashed] = true
        bands_args[:alias] = "#{args[:alias]} Confidence"
        field "#{name}_bands", bands_args

        field name, args
    end

    def field(name, args)
        raise "A field called #{name} already exist for this graph" if targets.include?(name)

        default = {}

        if @service_mode
            default[:data] = [info[:hostname], @service_mode[:service], @service_mode[:data], name].join(".")
        end

        targets[name] = default.merge(args)
        target_order << name
    end

    def url(format = nil)
        return nil if properties[:surpress]

        url_parts = []
        colors = []

        [:title, :vtitle, :from, :width, :height].each do |item|
            url_parts << "#{item}=#{properties[item]}"
        end

        url_parts << "areaMode=#{properties[:area]}"

        target_order.each do |name|
            target = targets[name]

            if target[:target]
                url_parts << "target=#{target[:target]}"
            else
                raise "field #{name} does not have any data associated with it" unless target[:data]

                graphite_target = target[:data]

                graphite_target = "derivative(#{graphite_target})" if target[:derivative]
                graphite_target = "scale(#{graphite_target},#{target[:scale]})" if target[:scale]
                graphite_target = "drawAsInfinite(#{graphite_target})" if target[:line]

                graphite_target = "color(#{graphite_target},\"#{target[:color]}\")" if target[:color]
                graphite_target = "dashed(#{graphite_target})" if target[:dashed]

                if target[:alias]
                    graphite_target = "alias(#{graphite_target},\"#{target[:alias]}\")"
                else
                    graphite_target = "alias(#{graphite_target},\"#{name.to_s.capitalize}\")"
                end

                url_parts << "target=#{graphite_target}"
            end
        end

        url_parts << "format=#{format}" if format

        url_parts.join("&")
    end
end

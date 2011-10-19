# A small DSL to assist in the creation of Graphite graphs
# see https://github.com/ripienaar/graphite-graph-dsl/wiki
# for full details
class GraphiteGraph
  attr_reader :info, :properties, :targets, :target_order

  def initialize(file, overrides={}, info={})
    @info = info
    @file = file
    @munin_mode = false
    @overrides = overrides
    @linecount = 0

    load_graph
  end

  def defaults
    @properties = {:title => nil,
                   :vtitle => nil,
                   :width => 500,
                   :height => 250,
                   :from => "-1hour",
                   :unil => "now",
                   :surpress => false,
                   :description => nil,
                   :hide_legend => nil,
                   :ymin => nil,
                   :ymax => nil,
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

    self.instance_eval(File.read(@file)) unless @file == :none
  end

  def service(service, data, &blk)
    raise "No hostname given for this instance" unless info[:hostname]

    @service_mode = {:service => service, :data => data}

    blk.call

    @service_mode = false
  end

  # add forecast, bands, aberrations and actual fields using the
  # Holt-Winters Confidence Band prediction model
  #
  #    hw_predict :foo, :data => "some.data.item", :alias => "Some Item"
  #
  # You can tweak the colors by setting:
  #     :forecast_color => "blue"
  #     :bands_color => "grey"
  #     :aberration_color => "red"
  #
  # You can add an aberration line:
  #
  #     :aberration_line => true,
  #     :aberration_second_y => true
  #
  # You can disable the forecast line by setting:
  #
  #     :forecast_line => false
  #
  # You can disable the confidence lines by settings:
  #
  #     :bands_lines => false
  #
  # You can disable the display of the actual data:
  #
  #     :actual_line => false
  def hw_predict(name, args)
    raise ":data is needed as an argument to a Holt-Winters Confidence forecast" unless args[:data]

    unless args[:forecast_line] == false
      forecast_args = args.clone
      forecast_args[:data] = "holtWintersForecast(#{forecast_args[:data]})"
      forecast_args[:alias] = "#{args[:alias]} Forecast"
      forecast_args[:color] = args[:forecast_color] || "blue"
      field "#{name}_forecast", forecast_args
    end

    unless args[:bands_lines] == false
      bands_args = args.clone
      bands_args[:data] = "holtWintersConfidenceBands(#{bands_args[:data]})"
      bands_args[:color] = args[:bands_color] || "grey"
      bands_args[:dashed] = true
      bands_args[:alias] = "#{args[:alias]} Confidence"
      field "#{name}_bands", bands_args
    end

    if args[:aberration_line]
      aberration_args = args.clone
      aberration_args[:data] = "holtWintersAberration(keepLastValue(#{aberration_args[:data]}))"
      aberration_args[:color] = args[:aberration_color] || "orange"
      aberration_args[:alias] = "#{args[:alias]} Aberation"
      aberration_args[:second_y_axis] = true if aberration_args[:aberration_second_y]
      field "#{name}_aberration", aberration_args
    end

    if args[:critical]
      [args[:critical]].flatten.each_with_index do |crit, index|
        color = args[:critical_color] || "red"
        caption = "#{args[:alias]} Critical"

        line :caption => "#{name}_crit_#{index}", :value => crit, :color => color, :dashed => true
      end
    end

    if args[:warning]
      [args[:warning]].flatten.each_with_index do |warn, index|
        color = args[:warning_color] || "orange"
        caption = "#{args[:alias]} Warning"

        line :caption => "#{name}_warn_#{index}", :value => warn, :color => color, :dashed => true
      end
    end

    args[:color] ||= "yellow"

    field name, args unless args[:actual_line] == false
  end

  alias :forecast :hw_predict

  # draws a simple line on the graph with a caption, value and color.
  #
  # line :caption => "warning", :value => 50, :color => "orange"
  def line(options)
    raise "lines need a caption" unless options.include?(:caption)
    raise "lines need a value" unless options.include?(:value)
    raise "lines need a color" unless options.include?(:color)

    args = {:data => "threshold(#{options[:value]})", :color => options[:color], :alias => options[:caption]}

    args[:dashed] = true if options[:dashed]

    field "line_#{@linecount}", args

    @linecount += 1
  end

  # adds a field to the graph, each field needs a unique name
  def field(name, args)
    raise "A field called #{name} already exist for this graph" if targets.include?(name)

    default = {}

    if @service_mode
      default[:data] = [info[:hostname], @service_mode[:service], @service_mode[:data], name].join(".")
    end

    targets[name] = default.merge(args)
    target_order << name
  end

  def url(format = nil, url=true)
    return nil if properties[:surpress]

    url_parts = []
    colors = []

    [:title, :vtitle, :from, :width, :height, :until].each do |item|
      url_parts << "#{item}=#{properties[item]}" if properties[item]
    end

    url_parts << "areaMode=#{properties[:area]}" if properties[:area]
    url_parts << "hideLegend=#{properties[:hide_legend]}" if properties.include?(:hide_legend)
    url_parts << "yMin=#{properties[:ymin]}" if properties[:ymin]
    url_parts << "yMax=#{properties[:ymax]}" if properties[:ymax]

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
        graphite_target = "secondYAxis(#{graphite_target})" if target[:second_y_axis]

        if target[:alias]
          graphite_target = "alias(#{graphite_target},\"#{target[:alias]}\")"
        else
          graphite_target = "alias(#{graphite_target},\"#{name.to_s.capitalize}\")"
        end

        url_parts << "target=#{graphite_target}"
      end
    end

    url_parts << "format=#{format}" if format

    if url
      url_parts.join("&")
    else
      url_parts
    end
  end
end

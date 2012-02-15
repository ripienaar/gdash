class GDash
  class Dashboard
    attr_accessor :properties

    def initialize(short_name, dir, options={})
      raise "Cannot find dashboard directory #{dir}" unless File.directory?(dir)

      @properties = {:graph_width => nil,
                     :graph_height => nil,
                     :graph_from => nil,
                     :graph_until => nil}

      @properties[:short_name] = short_name
      @properties[:directory] = File.join(dir, short_name)
      @properties[:yaml] = File.join(dir, short_name, "dash.yaml")

      raise "Cannot find YAML file #{yaml}" unless File.exist?(yaml)

      @properties.merge!(YAML.load_file(yaml))

      # Properties defined in dashboard config file are overridden when given on initialization
      @properties[:graph_width] = options.delete(:width) || graph_width
      @properties[:graph_height] = options.delete(:height) || graph_height
      @properties[:graph_from] = options.delete(:from) || graph_from
      @properties[:graph_until] = options.delete(:until) || graph_until
    end

    def graphs(options={})
      options[:width] ||= graph_width
      options[:height] ||= graph_height
      options[:from] ||= graph_from
      options[:until] ||= graph_until

      graphs = Dir.entries(directory).select{|f| f.match(/\.graph$/)}

      overrides = options.reject { |k,v| v.nil? }

      graphs.sort.map do |graph|
        {:name => File.basename(graph, ".graph"), :graphite => GraphiteGraph.new(File.join(directory, graph), overrides)}
      end
    end

    def method_missing(method, *args)
      if properties.include?(method)
        properties[method]
      else
        super
      end
    end
  end
end

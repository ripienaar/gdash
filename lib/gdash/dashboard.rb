class GDash
  class Dashboard
    attr_accessor :properties

    def initialize(short_name, graph_templates, category, options={}, graphite_render="")
      @properties = {:graph_width => nil,
				:graph_height => nil,
				:graph_from => nil,
				:graph_until => nil}

      @properties[:short_name] = short_name
      @properties[:graph_templates] = graph_templates
      @properties[:category] = category
      @properties[:graphite_render] = graphite_render
      
      @properties[:directory] = File.join(graph_templates, category, short_name)
      
      raise "Cannot find dashboard directory #{directory}" unless File.directory?(directory)
      
      @properties[:yaml] = File.join(directory, "dash.yaml")

      raise "Cannot find YAML file #{yaml}" unless File.exist?(yaml)

      @properties.merge!(YAML.load_file(yaml))

      if @properties[:include_properties] == nil || @properties[:include_properties].empty?
        property_includes = []
      elsif @properties[:include_properties].is_a? Array
        property_includes = @properties[:include_properties]
      elsif @properties[:include_properties].is_a? String
        property_includes = [@properties[:include_properties]]
      else
        raise "Invalid value for include_properties in #{File.join(directory, 'dash.yaml')}"
      end

      property_includes << options[:include_properties] if options[:include_properties]

      for property_file in property_includes
        yaml_file = File.join(graph_templates, property_file)
        if File.exist?(yaml_file)
          @properties.rmerge!(YAML.load_file(yaml_file))
        end
      end
 	
      if @properties[:include_graphs] == nil || @properties[:include_graphs].empty?
        graph_includes = []
      elsif @properties[:include_graphs].is_a? Array
        graph_includes = @properties[:include_graphs]
      elsif @properties[:include_graphs].is_a? String
        graph_includes = [@properties[:include_graphs]]
      else
        raise "Invalid value for include in #{File.join(directory, 'graph.yaml')}"
      end

      @directories = graph_includes.map { |d|
        File.join(graph_templates, d)
      }
      @directories << directory

      # Properties defined in dashboard config file are overridden when given on initialization
      @properties.rmerge!(options)
      @properties[:graph_width] = options.delete(:width) || graph_width
      @properties[:graph_height] = options.delete(:height) || graph_height
      @properties[:graph_from] = options.delete(:from) || graph_from
      @properties[:graph_until] = options.delete(:until) || graph_until

      #Graphite defined in gdash.yaml is overwritten if set in dash.yaml
      if !(@properties[:graphite] == nil || @properties[:graphite].empty?)
        @properties[:graphite_render] = @properties[:graphite]+"/render"
      end
    end

    def list_graphs()
      graphs = {}
      @directories.each { |directory|
        current_graphs = Dir.entries(directory).select {|f| f.match(/\.graph$/)}
        current_graphs.each { |graph_filename|  
          graph_name = File.basename(graph_filename, ".graph")
          graphs[graph_name] = File.join(directory, graph_filename) 
        }
      }
      graphs
    end
    
    def graphs_named(options={})
      options[:width] ||= graph_width
      options[:height] ||= graph_height
      options[:from] ||= graph_from
      options[:until] ||= graph_until

      graphs = list_graphs()

      overrides = options.reject { |k,v| v.nil? }
      overrides = overrides.merge!(@properties[:graph_properties]) if @properties[:graph_properties]

      graphs_named = Hash.new
      graphs.each do |graph_name, graph_path|
				graphs_named[graph_name] = {
					:name => graph_name,
					:graphite => GraphiteGraph.new(File.join(graph_path), overrides)
				}
      end

      graphs_named
    end

    def graphs(options={})
      graphs_named(options).sort.map { |k,v| v } 
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
  

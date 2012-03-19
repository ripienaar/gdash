class GDash
  class Dashboard
    attr_accessor :properties

    def initialize(short_name, dir, graph_width=500, graph_height=250)
      raise "Cannot find dashboard directory #{dir}" unless File.directory?(dir)

      @properties = {}

      @properties[:short_name] = short_name
      @properties[:directory] = File.join(dir, short_name)
      @properties[:yaml] = File.join(dir, short_name, "dash.yaml")
      @properties[:graph_width] = graph_width
      @properties[:graph_height] = graph_height

      raise "Cannot find YAML file #{yaml}" unless File.exist?(yaml)

      @properties.merge!(YAML.load_file(yaml))
    end

    def list_graphs(directories)
      graphs = {}
      directories.each { |directory|
        current_graphs = Dir.entries(directory).select {|f| f.match(/\.graph$/)}
        current_graphs.each { |graph_filename|  
          graph_name = File.basename(graph_filename, ".graph")
          graphs[graph_name] = File.join(directory, graph_filename) 
        }
      }
      graphs
    end

    def graphs(width=nil, height=nil)
      height ||= graph_height
      width ||= graph_width
        
      if @properties[:include] == nil || @properties[:include].empty?
        includes = []
      elsif @properties[:include].is_a? Array
        includes = @properties[:include]
      elsif @properties[:include].is_a? String
        includes = [@properties[:include]]
      else
        raise "Invalid value from includes"
      end

      directories = includes.map { |d|
        File.join(directory, '..', '..', d)
      }
      directories << directory

      graphs = list_graphs(directories)

      graphs.keys.sort.map do |graph_name|
        {:name => graph_name, 
         :graphite => GraphiteGraph.new(graphs[graph_name], 
                      {:height => height, :width => width}, 
                       {}, 
                       @properties[:graph_properties])}
                       
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

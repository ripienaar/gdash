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

        def graphs(width=nil, height=nil)
            height ||= graph_height
            width ||= graph_width

            graphs = Dir.entries(directory).select{|f| f.match(/\.graph$/)}

            graphs.sort.map do |graph|
                {:name => File.basename(graph, ".graph"), :graphite => GraphiteGraph.new(File.join(directory, graph), {:height => height, :width => width})}
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

class GDash
    class Dashboard
        attr_accessor :properties

        def initialize(short_name, dir, graph_width=500, graph_height=250, graph_from="-1hour", graph_until="now")
            raise "Cannot find dashboard directory #{dir}" unless File.directory?(dir)

            @properties = {}

            @properties[:short_name] = short_name
            @properties[:directory] = File.join(dir, short_name)
            @properties[:yaml] = File.join(dir, short_name, "dash.yaml")
            @properties[:graph_width] = graph_width
            @properties[:graph_height] = graph_height
            @properties[:graph_from] = graph_from
            @properties[:graph_until] = graph_until

            raise "Cannot find YAML file #{yaml}" unless File.exist?(yaml)

            @properties.merge!(YAML.load_file(yaml))
        end

        def graphs(width=nil, height=nil, from=nil, untiltime=nil)
            height ||= graph_height
            width ||= graph_width
            from ||= graph_from
            untiltime ||= graph_until

            graphs = Dir.entries(directory).select{|f| f.match(/\.graph$/)}

            graphs.sort.map do |graph|
                {:name => File.basename(graph, ".graph"), :graphite => GraphiteGraph.new(File.join(directory, graph), {:height => height, :width => width, :from => from, :until => untiltime})}
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

class GDash
  # a representation of a node, this is kind of just exploring how this might look and is
  # probably quite specific to my case and is very likely to change significantly soon
  #
  # My data looks like:
  #
  # some_node_com -> munin -> cpu -> iowait, idle, etc
  #
  # So here a node class represents some_node_com.  Not all my nodes have the munin
  # data so I would restrict the list to only nodes that has the data in this structure
  # using:
  #
  #    Node.list("/some/data/dir", "munin")
  #
  # I would then have services which would be 'cpu' in the above example and metrics
  # that would be iowait, idle, etc.
  class Node
    attr_accessor :properties

    class << self
      # gets a list of 'nodes' in the whisper directory - basically just all subdirs.
      #
      # If you supply the optional 2nd param it will only return nodes with that subdir
      def list(whisper_dir, with="")
        raise "Cannot find whisper directory #{whisper_dir}" unless File.directory?(whisper_dir)

        Dir.entries(whisper_dir).select do |dir|
          File.directory?(File.join(whisper_dir, dir, with))
        end.sort
      end
    end

    def initialize(node_name, template_dir, whisper_dir)
      @properties = {}
      @properties[:name] = node_name
      @properties[:display_name] = node_name.gsub("_", ".")
      @properties[:whisper_dir] = whisper_dir
      @properties[:template_dir] = template_dir
      @properties[:node_dir] = File.join(whisper_dir, node_name)

      raise "Cannot find whisper directory #{whisper_dir}" unless File.directory?(whisper_dir)
      raise "Cannot find node directory #{node_dir}" unless File.directory?(node_dir)
    end

    # a list of services, given the data layout:
    #
    # node/munin/cpu, exim
    #
    # services("munin") will return ["cpu", "exim"]
    def services(type)
      dir = File.join(whisper_dir, name, type.to_s)

      services = []

      if File.directory?(dir)
        Dir.entries(dir).sort.select do |service|
          unless service.match(/^\./)
            if File.directory?(File.join(dir, service))
              services << service
            end
          end
        end
      end

      services
    end

    # looks for all the wsp files in a specific nodes data dirs
    def metrics(type, service)
      datadir = File.join(whisper_dir, name, type.to_s, service.to_s)

      Dir.entries(datadir).grep(/\.wsp$/).sort.map do |metric|
        File.basename(metric, ".wsp")
      end
    end

    # builds a default best-efforts style graph for a metric that has no hints
    def default_graph(type, service, options={})
        graph = GraphiteGraph.new(:none, options, :hostname => name)
        graph.title "%s:%s @ %s" % [type, service, display_name]
        graph.area :all
        graph.hide_legend false

        metrics(type, service).each do |metric|
          graph.field metric, :data => [name, type, service, metric].join("."),
                              :alias => metric.capitalize
        end

        graph
    end

    # builds an array of GraphiteGraph objects for a service.
    def service_graphs(type, service, options={})
      options = {:from => "-12hours",
                 :height => 250,
                 :width => 500}.merge(options)

      templ_dir = File.join(template_dir, type.to_s, service.to_s)
      templ_file = File.join(template_dir, type.to_s, "#{service}.graph")

      graphs = []

      # if there is a simple machine/munin/cpu.graph use it to display cpu/*
      if File.exist?(templ_file)
        graphs << GraphiteGraph.new(templ_file, options, :hostname => name, :type => type, :service => service, :metrics => metrics(type, service))

      # if there is a dir machine/munin/cpu/ use *.graph in it
      elsif File.directory?(templ_dir)
        Dir.entries(templ_dir).grep(/\.graph$/) do |graph|
          data = "%s.%s.%s.%s" % [ name, type, service, File.basename(graph, ".graph") ]
          graphs << GraphiteGraph.new(File.join(templ_dir, graph), options, :hostname => name, :type => type, :service => service, :data => data)
        end

      # else construct a one size fits all graph
      else
        graphs << default_graph(type, service, options)
      end

      return graphs
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

What?
=====

A simple Graphite dashboard built using Twitter's Bootstrap.

Adding new dashboards is very easy and individual graphs are
described using a small DSL.

See the _sample_ directory for a sample dashboard configuration.

![Sample dashboard](https://github.com/ripienaar/gdash/raw/master/sample/email.png)

Config?
-------

This dashboard is a Sinatra application, I suggest deploying it
in Passenger or other Sinatra application server.

A sample _gdash.yaml-sample_ is included, you should rename it to
_gdash.yaml_ and adjust the url to your Graphite etc in there.

The SinatraApp class take two required arguments:

    * Where graphite is installed
    * The directory that has your _dashboards_ directory full of templates

and additional options:

    * The title to show at the top of your Graphite
    * A prefix to prepend to all URLs in the dashboard
    * How many columns of graphs to create, 2 by default.
    * How often dashboard page is refreshed, 60 sec by default.
    * The width of the graphs, 500 by default
    * The height of the graphs, 250 by default
    * Where your whisper files are stored - future use
    * Optional interval quick filters

Creating Dashboards?
--------------------

You can have multiple top level categories of dashboard.  Just create directories
in the _templatedir_ for each top level category.

In each top level category create a sub directory with a short name for each new dashboard.

You need a file called _dash.yaml_ for each dashboard, here is a sample:

    :name: Email Metrics
    :description: Hourly metrics for the email system

Then create descriptions in files like _cpu.graph_ in the same directory, here
is a sample:

    title       "Combined CPU Usage"
    vtitle      "percent"
    area        :stacked
    description "The combined CPU usage for all Exim Anti Spam servers"

    field :iowait, :scale => 0.001,
                   :color => "red",
                   :alias => "IO Wait",
                   :data  => "sumSeries(derivative(mw*munin.cpu.iowait))"

    field :system, :scale => 0.001,
                   :color => "orange",
                   :alias => "System",
                   :data  => "sumSeries(derivative(mw*.munin.cpu.system))"

    field :user, :scale => 0.001,
                 :color => "yellow",
                 :alias => "User",
                 :data  => "sumSeries(derivative(mw*.munin.cpu.user))"

The dashboard will use the _description_ field to show popup information bubbles
when someone hovers over a graph with their mouse for 2 seconds.

The graphs are described using a DSL that has its own project and documented
over at https://github.com/ripienaar/graphite-graph-dsl/wiki

At the moment we do not support the _Related Items_ feature of the DSL.

Template Directory Layout?
--------------------------

The directory layout is such that you can have many groupins of dashboards each with
many dashboards underneath it, an example layout of your templates dir would be:

        graph_templates
        `-- virtualization
            |-- dom0
            |   |-- dash.yaml
            |   |-- iowait.graph
            |   |-- load.graph
            |   |-- system.graph
            |   |-- threads.graph
            |   `-- user.graph
            `-- kvm1
                |-- dash.yaml
                |-- disk_read.graph
                |-- disk_write.graph
                |-- ssd_read.graph
                `-- ssd_write.graph

Here we have a group of dashboards called 'virtualization' with 2 dashboards inside it
each with numerous graphs.

You can create as many groups as you want each with many dashboards inside.

Custom Time Intervals?
--------------------

You can reuse your dashboards and adjust the time interval by using the following url
structure:

    http://gdash.example.com/dashboard/email/time/-8d/-7d

or

    http://gdash.example.com/dashboard/email/?from=-8d&until=-7d
    http://gdash.example.com/dashboard/email/full/2/600/300?from=-8d&until=-7d

This will display the _email_ dashboard with a time interval same day last week.
If you hit */dashboard/email/time/* it will default to the past hour (*-1hour*)
See http://graphite.readthedocs.org/en/1.0/url-api.html#from-until for more info
acceptable *from* and *until* values.

Quick interval filters shown in interface are configurable in _gdash.yaml_ options sections. Eg:

	:options:
           :interval_filters:
             - :label: Last Hour
               :from: -1h
               :to: now
             - :label: Last Day
               :from: -1day
             - :label: Current Week
               :from: monday
               :to: now

Quick filter is not shown when *interval_filters* section is missing in configuration file.

Time Intervals Display?
-----------------------

If you configure time intervals in the config file you can click on any graph in
the main dashboard view and get a view with different time intervals of the same
graph

	:options:
	  :intervals:
	    - [ "-1hour", "1 hour" ]
	    - [ "-2hour", "2 hour" ]
	    - [ "-1day", "1 day" ]
	    - [ "-1month", "1 month" ]
	    - [ "-1year", "1 year" ]

With this in place in the _config.yaml_ clicking on a graph will show the 5 intervals
defined above of that graph

Full Screen Displays?
---------------------

You can reuse your dashboards for big displays against a wall in your NOC or office
by using the following url structure:

    http://gdash.example.com/dashboard/email/full/4/600/300
    http://gdash.example.com/dashboard/email/full/4?width=600&height=300

This will display the _email_ dashboard in _4_ columns each graph with a width of
_600_ and a height of _300_

The screen will refresh every minute

Additional properties in graphs?
--------------------------------

You can specify additional properties in the dash.yaml:

    :graph_properties:
        :environment: dev
        :server: [ a_server_name ]
        :javaid: 1234
    
that can be accessed from the .graph like:
    
    server = @properties[:server]
    environment = @properties[:environment]
    
    field :iowait, 
        :alias => "IO Wait #{server}",
        :data  => "servers.#{environment}.#{server}.cpu*.cpu-{system,wait}.value"

Include graphs from other dashboard?
------------------------------------

You can include the graphs from other dashboard with the include 
property in dash.yaml:

    :include: 
    - "templates/os.basic" 
    - "templates/os.nfs" 

Two new features:

Allow override graph properties from the dash.yaml.
Support include the graphs from other dashboards in dash.yaml
These two features allow you create a set of templates that you can include and parametrize, like this:

	└── graph_templates
	    ├── live
	    │   ├── 3_OS_server0001
	    │   │   └── dash.yaml
	    │   ├── 3_OS_server0002
	    │   │   └── dash.yaml
	    │   ├── 3_OS_live_all
	    │   │   └── dash.yaml
	    └── templates
		├── os.basic
		│   ├── 10-cpu.graph
		│   ├── 20-load.graph
		│   ├── 25-memory.graph
		│   ├── 26-swap-io.graph
		│   ├── 30-network.graph
		│   ├── 40-processes.graph
		│   ├── 80-io.graph
		│   ├── 81-io-time.graph
		│   ├── 82-io-ops.graph
		│   └── 90-df.graph
		├── os.basic_multi
		│   ├── 10-cpu-multi.graph
		│   ├── 30-network-multi.graph
		│   ├── 80-io-multi.graph
		│   ├── 81-io-time-multi.graph
		│   └── 82-io-ops-multi.graph
		├── os.marklogic
		│   ├── 92-ml-volumes-df.graph
		│   └── 93-ml-volumes-df.graph
		└── os.nfs
		     ├── 91-nfs-basic.graph
		     ├── 92-nfs-detailed.graph
		     └── 93-slabinfo.graph

In the dash.yaml you can include the graphs as an include and override some properties:

	:name: "OS slnldogo0002"
	:description: "OS slnldogo0002: slnldogo0002_springer-sbm_com"

	:include: 
	 - "templates/os.basic" 
	 - "templates/os.nfs" 
	:graph_properties: 
	 :environment: live
	 :servers: [ server0001, server0002 ]
	And in the graphs:

	title       "Combined CPU Usage"
	vtitle      "percent"
	linemode    "connected" 
	timezone    "Europe/London"
	description "The combined CPU usage for all core servers"

	servers = @properties[:servers] 
	environment = @properties[:environment] 

	server_definition = (servers.is_a? Array) ? "{#{servers.join(',')}}" : servers

	field :iowait, :scale => 0.1,
		       :color => "yellow",
		       :alias => "IO Wait",
		       :data  => "sumSeries(nonNegativeDerivative(servers.#{server_definition}.cpu*.cpu-{system,wait}.value))",
		       :smoothing => 3

	field :user,   :scale => 0.1,
		       :color => "green",
		       :alias => "User",
		       :data  => "sumSeries(nonNegativeDerivative(servers.#{server_definition}.cpu*.cpu-user.value))",
		       :smoothing => 3

	field :other,  :scale => 0.1,
		       :color => "red",
		       :alias => "Other",
		       :data  => "sumSeries(nonNegativeDerivative(servers.#{server_definition}.cpu-*.cpu-{interrupt,softirq,steal}.value))",
		       :smoothing => 3

	field :idle,   :scale => 0.1,
		       :color => "grey",
		       :alias => "idle",
		       :data  => "sumSeries(nonNegativeDerivative(servers.#{server_definition}.cpu-*.cpu-idle.value))",
		       :smoothing => 3

We got to access this properties as @properties[:servers] because the missing_method disallows access the overrides directly, not sure why.


Contact?
--------

R.I.Pienaar / rip@devco.net / http://www.devco.net/ / @ripienaar

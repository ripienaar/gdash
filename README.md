What?
=====

A simple Graphite dashboard built using Twitters Bootstrap.

Adding new dashboards is very easy and individual graphs is
described using a small DSL.

See the _sample_ directory for an example dashboard including
a screenshot.

Config?
-------

This dashboard is a Sinatra application, I suggest deploying it
in Passenger or other Sinatra application server.

A sample _config.ru_ is included, you should adjust the url to
your Graphite etc in there.


    templatedir = File.join(File.dirname(__FILE__), "graph_templates")

    run GDash::SinatraApp.new("http://graphite.example.net/", templatedir, "My Dashboard")

The SinatraApp class can take a number of arguments:

    * Where graphite is installed
    * The directory that has your _dashboards_ directory full of templates
    * The title to show at the top of your Graphite
    * A prefix to prepend to all URLs in the dashboard
    * How many columns of graphs to create, 2 by default.
    * The width of the graphs, 500 by default
    * The height of the graphs, 250 by default
    * Where your whisper files are stored - future use

Creating Dashboards?
--------------------

Simply create a sub directory with a short name for your new dashboard under
the _templatedir_.

You need a file called _dash.yaml_ in there, here is a sample:

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

Full Screen Displays?
---------------------

You can reuse your dashboards for big displays against a wall in your NOC or office
by using the following url structure:

    http://gdash.example.com/dashboard/email/full/4/600/300

This will display the _email_ dashboard in _4_ columns each graph with a width of
_600_ and a height of _300_

The screen will refresh every minute

Contact?
--------

R.I.Pienaar / rip@devco.net / http://www.devco.net/ / @ripienaar

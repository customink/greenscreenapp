require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'erb'
require 'rexml/document'
require 'hpricot'
require 'open-uri'

get '/' do
  servers = YAML.load_file 'config.yml'
  return "Add the details of build server to the config.yml file to get started" unless servers

  @projects = []

  servers.each do |server|
    open_opts = {}
    if server["username"] || server["password"]
      open_opts[:http_basic_authentication] = [ server["username"], server["password"] ]
    end
    xml = REXML::Document.new(open(server["url"], open_opts))
    projects = xml.elements["//Projects"]

    job_matchers =
      if server["jobs"]
        server["jobs"].collect do |j|
          if j =~ %r{^/.*/$}
            Regexp.new(j[1..(j.size-2)])
          else
            Regexp.new("^#{Regexp.escape(j)}$")
          end
        end
      end

    projects.each do |project|
      monitored_project = MonitoredProject.new(project)
      if job_matchers
        if job_matchers.detect { |matcher| monitored_project.name =~ matcher }
          @projects << monitored_project
        end
      else
        @projects << monitored_project
      end
    end
  end

  @projects = @projects.sort_by { |p| p.name.downcase }

  @columns = 1.0
  @columns = 2.0 if @projects.size > 4
  @columns = 3.0 if @projects.size > 10
  @columns = 4.0 if @projects.size > 21

  @rows = (@projects.size / @columns).ceil

  erb :index
end

class MonitoredProject
  attr_reader :name, :last_build_status, :activity, :last_build_time, :web_url, :last_build_label

  def initialize(project)
    @activity = project.attributes["activity"]
    @last_build_time = Time.parse(project.attributes["lastBuildTime"]).localtime
    @web_url = project.attributes["webUrl"]
    @last_build_label = project.attributes["lastBuildLabel"]
    @last_build_status = project.attributes["lastBuildStatus"].downcase
    @name = project.attributes["name"]
  end
end

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'erb'
require 'rexml/document'
require 'hpricot'
require 'open-uri'
require 'yaml'
require 'erb'

get '/' do
  servers = load_servers
  return "Add the details of build server to the config.yml file to get started" unless servers

  @projects = []

  servers.each do |server|
    open_opts = {}
    if server["username"] || server["password"]
      open_opts[:http_basic_authentication] = [ server["username"], server["password"] ]
    end
    begin
      xml = REXML::Document.new(open(server["url"], open_opts))
      @projects.push(*accumulate_projects(server, xml))
    rescue => e
      @projects.push(MonitoredProject.server_down(server, e))
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

def load_servers
  YAML.load(StringIO.new(ERB.new(File.read 'config.yml').result))
end

def accumulate_projects(server, xml)
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

  projects.collect do |project|
    monitored_project = MonitoredProject.create(project)
    if job_matchers
      if job_matchers.detect { |matcher| monitored_project.name =~ matcher }
        monitored_project
      end
    else
      monitored_project
    end
  end.flatten.compact
end

class MonitoredProject
  attr_accessor :name, :last_build_status, :activity, :last_build_time, :web_url, :last_build_label

  def self.create(project)
    MonitoredProject.new.tap do |mp|
      mp.activity = project.attributes["activity"]
      mp.last_build_time = Time.parse(project.attributes["lastBuildTime"]).localtime
      mp.web_url = project.attributes["webUrl"]
      mp.last_build_label = project.attributes["lastBuildLabel"]
      mp.last_build_status = project.attributes["lastBuildStatus"].downcase
      mp.name = project.attributes["name"]
    end
  end

  def self.server_down(server, e)
    MonitoredProject.new.tap do |mp|
      mp.name = e.to_s
      mp.last_build_time = Time.now.localtime
      mp.last_build_label = server["url"]
      mp.web_url = server["url"]
      mp.last_build_status = "Failure"
      mp.activity = "Sleeping"
    end
  end

  def building?
    self.activity =~ /building/i
  end
end

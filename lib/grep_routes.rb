require 'active_support'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/enumerable'
require 'action_dispatch'

class GrepRoutes
  class Rails
    def self.env
      @_env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development")
    end
  end
  
  attr_reader :path_to_routes_file
  attr_reader :route_file
  attr_reader :class_name
  
  def initialize(path_to_routes_file)
    @path_to_routes_file = path_to_routes_file
    @route_file = File.read(path_to_routes_file)
    @class_name = route_file.match(/(\w+)::Application\.routes\.draw/)[1]
    self.init_rails_class
    self.init_rack_apps
  end
  
  # only the last class needs to have #call defined on it but all the objects
  # "above" it need to be defined as Modules - basically define the object heirarchy
  def init_rails_class
    rails_app.module_eval do
      self.const_set('Application', Class.new) unless self.const_defined?('Application')
      self.const_get('Application', Class.new).class_eval do
        def self.routes
          @routes ||= ActionDispatch::Routing::RouteSet.new
        end
      end
    end
  end
  
  # only the last class needs to have #call defined on it but all the objects
  # "above" it need to be defined as Modules - basically define the object heirarchy
  def init_rack_apps
    rack_apps = route_file.scan(/mount (.+?\s+)/).flatten.map(&:strip)
    rack_apps.each do |class_name|
      objects = class_name.split("::")
      rack_class = objects.pop
      last_object = Object
      objects.each do |obj|
         last_object.const_set(obj, Module.new) unless last_object.const_defined?(obj)
         last_object = last_object.const_get(obj)
      end
      make_rackapp(last_object, rack_class)
    end
  end
  
  def make_rackapp(mod, obj)
    mod.const_set(obj,Class.new) unless mod.const_defined?(obj)
    mod.const_get(obj,Class.new).class_eval do
      def self.call
      end
    end
  end
  
  def rails_app
    Object.const_set(class_name,Module.new) unless Object.const_defined?(class_name)
    Object.const_get(class_name,Module.new)
  end
  
  def eval_routes
    eval(route_file)
  end
  
  def route_set
    rails_app.const_get('Application', Class.new).routes
  end
  
  def routes
    return @routes if @routes
    
    @routes = route_set.routes.collect do |route|
      reqs = route.requirements.dup
      reqs[:to] = route.app unless route.app.class.name.to_s =~ /^ActionDispatch::Routing/
      reqs = reqs.empty? ? "" : reqs.inspect
      {:name => route.name.to_s, :verb => route.verb.to_s, :path => route.path, :reqs => reqs}
    end
     # Skip the route if it's internal info route
    @routes.reject! { |r| r[:path] =~ %r{/rails/info/properties|^/assets} }
    return @routes
  end
  
  def filter_routes(pattern)
    @routes = routes.select{|r| "#{r[:name]} #{r[:verb]} #{r[:path]} #{r[:reqs]}".match pattern}
  end
  
  def formatted_routes
    name_width = routes.map{ |r| r[:name].length }.max
    verb_width = routes.map{ |r| r[:verb].length }.max
    path_width = routes.map{ |r| r[:path].length }.max
    
    routes.collect do |r|
      "#{r[:name].rjust(name_width)} #{r[:verb].ljust(verb_width)} #{r[:path].ljust(path_width)} #{r[:reqs]}"
    end
  end
  
  def print
    puts formatted_routes
  end
  
end
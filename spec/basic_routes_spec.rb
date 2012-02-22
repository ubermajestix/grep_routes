require 'spec_helper'

describe GrepRoutes do
  subject do
    GrepRoutes.new('spec/fixtures/routes.rb')
  end
  
  it "should set the path to the routes file as an instance var" do
    subject.path_to_routes_file.must_equal 'spec/fixtures/routes.rb'
  end
  
  it "should define the rails application class from the routes file" do
    subject.rails_app.to_s.must_equal 'Concourse'
  end
  
  it "should have a shortcut to the RouteSet" do
    subject.route_set.must_be_kind_of ActionDispatch::Routing::RouteSet
  end
  
  it "should the route set should be empty before we eval" do
    subject.route_set.routes.must_be_empty
  end
  
  it "there should be routes after we eval the routes file" do
    subject.eval_routes
    subject.route_set.routes.wont_be_empty
  end
  
  it "should print" do
    subject.eval_routes
    subject.print
  end
end
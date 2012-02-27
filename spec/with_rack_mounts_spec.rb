require 'spec_helper'

describe GrepRoutes do
  
  subject do
    gr = GrepRoutes.new('spec/fixtures/routes_with_rack_mounts.rb')
    gr.eval_routes
    gr
  end
  
  it "should have a route for Tolk" do
    subject.routes.map{|r| r[:path]}.must_include "/tolk"
  end
  
  it "should have a route for Evergreen.rails" do
    subject.routes.map{|r| r[:path]}.must_include "/evergreen"
  end
  
  it "should have a route for WebSocket" do
    subject.routes.map{|r| r[:path]}.must_include "/socket"
  end
  
  it "should have a route for Server.new" do
    subject.routes.map{|r| r[:path]}.must_include "/server/new"
  end
  
  it "should not have any eval failures and be fast" do
    subject.eval_failures.must_equal 0
  end
  
end
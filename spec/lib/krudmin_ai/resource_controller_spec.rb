require "spec_helper"
require "rails"
require "action_controller/railtie"
require "krudmin_ai"

RSpec.describe KrudminAI::ResourceController do
  it "uses the controller namespace when resolving generated route helpers" do
    route_proxy = instance_double("RouteProxy")
    controller = described_class.allocate
    allow(controller).to receive(:controller_path).and_return("admin/orders")
    controller.define_singleton_method(:main_app) { route_proxy }

    expect(route_proxy).to receive(:public_send).with("admin_orders_path")

    controller.send(:route_helper, "orders_path")
  end

  it "keeps route helpers unprefixed for an unnamespaced resource" do
    route_proxy = instance_double("RouteProxy")
    controller = described_class.allocate
    allow(controller).to receive(:controller_path).and_return("orders")
    controller.define_singleton_method(:main_app) { route_proxy }

    expect(route_proxy).to receive(:public_send).with("orders_path")

    controller.send(:route_helper, "orders_path")
  end
end
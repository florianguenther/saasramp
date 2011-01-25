require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../acts_as_subscriber_spec'

class Subscriber
  include Saasramp::Acts::Subscriber

  class << self
    # ActiveRecord stubs so we don't have to actually inherit from ActiveRecord and have a database
    def has_one(*args); end
    def validates_associated(*args); end
  end
end

describe Subscriber, 'class' do
  context "when it acts as paranoid" do
    before :each do
      def Subscriber.paranoid?
        true
      end
    end

    it "should define polymorphic subscription association without dependency" do
      Subscriber.should_receive(:has_one).with(:subscription, :as => :subscriber)
      Subscriber.send(:acts_as_subscriber)
    end
  end

  context "when it does not act as paranoid" do
    it "should define polymorphic subscription association with dependency" do
      Subscriber.should_receive(:has_one).with(:subscription, :as => :subscriber, :dependent => :destroy)
      Subscriber.send(:acts_as_subscriber)
    end
  end

  it "should validate the associated subscription" do
    Subscriber.should_receive(:validates_associated).with(:subscription)
    Subscriber.send(:acts_as_subscriber)
  end
end

describe Subscriber, 'instance' do
  let(:subscriber) { Subscriber.send(:acts_as_subscriber); Subscriber.new }
  let(:plan) { (plan = SubscriptionPlan.new).tap { plan.stub!(:save).and_return(true) } }
  let(:subscription) { (subscription = Subscription.new).tap { subscription.stub!(:save).and_return(true) } }

  describe "setting the subscription_plan" do
    before :each do
      subscriber.stub!(:subscription).and_return(nil)
    end

    context "and plan is a SubscriptionPlan" do
      it "should set the @newplan instance variable" do
        subscriber.subscription_plan = plan
        subscriber.instance_variable_get('@newplan').should == plan
      end
    end

    context "and plan is given as an id string" do
      it "should find the plan by id" do
        SubscriptionPlan.should_receive(:find_by_id).with('1').and_return(plan)
        subscriber.subscription_plan = '1'
        subscriber.instance_variable_get('@newplan').should == plan
      end
    end

    context "and plan is given as a name string" do
      it "should find the plan by name" do
        SubscriptionPlan.should_receive(:find_by_name).with('Über').and_return(plan)
        subscriber.subscription_plan = 'Über'
        subscriber.instance_variable_get('@newplan').should == plan
      end
    end

    it "should not attempt to change the plan" do
      subscription.should_receive(:change_plan).never
      subscriber.subscription_plan = plan
    end

    context "when subscriber has a subscription" do
      before :each do
        subscriber.stub!(:subscription).and_return(subscription)
      end

      it "should change the plan" do
        subscription.should_receive(:change_plan).with(plan)
        subscriber.subscription_plan = plan
      end
    end
  end

  describe "getting the subscription_plan" do
    context "and subscriber does not have a subscription" do
      before :each do
        subscriber.stub!(:subscription).and_return(nil)
      end

      it "should return nil" do
        subscriber.subscription_plan.should be_nil
      end
    end

    context "and subscriber does have a subscription" do
      before :each do
        subscriber.stub!(:subscription).and_return(subscription)
      end

      it "should return the plan from subscription" do
        subscription.stub!(:plan).and_return(subscription)
        subscriber.subscription_plan.should_not be_nil
        subscriber.subscription_plan.should == subscriber.subscription.plan
      end
    end
  end
end
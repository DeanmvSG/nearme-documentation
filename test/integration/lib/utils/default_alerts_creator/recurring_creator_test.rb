require 'test_helper'

class Utils::DefaultAlertsCreator::RecurringCreatorTest < ActionDispatch::IntegrationTest

  setup do
    @recurring_creator = Utils::DefaultAlertsCreator::RecurringCreator.new
  end

  should 'create all' do
    @recurring_creator.expects(:create_analytics_email!).once
    @recurring_creator.expects(:create_share_email!).once
    @recurring_creator.expects(:create_request_photos_email!).once
    @recurring_creator.create_all!
  end

  context 'methods' do

    setup do
      stub_mixpanel
      @company = FactoryGirl.create(:company)
      @platform_context = PlatformContext.current
      PlatformContext.any_instance.stubs(:domain).returns(FactoryGirl.create(:domain, :name => 'custom.domain.com'))
    end

    should 'create_analytics_email' do
      @recurring_creator.create_analytics_email!
      assert_difference 'ActionMailer::Base.deliveries.size' do
        WorkflowStepJob.perform(WorkflowStep::RecurringWorkflow::Analytics, @company.id, @company.creator.id)
      end
      mail = ActionMailer::Base.deliveries.last
      assert_equal "#{@company.creator.first_name}, we have potential guests for you!", mail.subject
      assert mail.html_part.body.include?(@company.creator.first_name)
      assert_equal [@company.creator.email], mail.to
      assert mail.html_part.body.include?("Make sure you have plenty of photos, and that they are up to date. It will make your Desk look even better!")
      assert_contains 'href="http://custom.domain.com/', mail.html_part.body
      assert_not_contains 'href="http://example.com', mail.html_part.body
      assert_not_contains 'href="/', mail.html_part.body
    end

    should 'create_share_email' do
      @reservation = FactoryGirl.create(:past_reservation)
      @listing = @reservation.listing
      @user = @listing.administrator
      @recurring_creator.create_share_email!
      assert_difference 'ActionMailer::Base.deliveries.size' do
        WorkflowStepJob.perform(WorkflowStep::RecurringWorkflow::Share, @listing.id)
      end
      mail = ActionMailer::Base.deliveries.last
      assert_equal "Share your listing '#{@listing.name}' at #{@listing.location.street } and increase bookings!", mail.subject
      assert mail.html_part.body.include?(@user.first_name)
      assert_equal [@user.email], mail.to
      assert mail.html_part.body.include?("Share your listing on Facebook, Twitter, and LinkedIn, and start seeing #{@platform_context.decorate.lessees} book your Desk.")
      assert mail.html_part.body.include?(@listing.name)
      assert_contains 'href="http://custom.domain.com/', mail.html_part.body
      assert_not_contains 'href="http://example.com', mail.html_part.body
      assert_not_contains 'href="/', mail.html_part.body
    end

    should 'create_request_photos_email' do
      @listing = FactoryGirl.create(:transactable)
      @user = @listing.administrator
      @recurring_creator.create_request_photos_email!
      assert_difference 'ActionMailer::Base.deliveries.size' do
        WorkflowStepJob.perform(WorkflowStep::RecurringWorkflow::RequestPhotos, @listing.id)
      end
      mail = ActionMailer::Base.deliveries.last
      assert_equal "Give the final touch to your #{PlatformContext.current.decorate.bookable_noun} with some photos!", mail.subject
      assert mail.html_part.body.include?(@user.first_name)
      assert_equal [@user.email], mail.to
      assert mail.html_part.body.include?("Listings with photos have 10x chances of getting booked.")
      assert mail.html_part.body.include?(@listing.name)
      assert_contains 'href="http://custom.domain.com/', mail.html_part.body
      assert_not_contains 'href="http://example.com', mail.html_part.body
      assert_not_contains 'href="/', mail.html_part.body
    end
  end

end

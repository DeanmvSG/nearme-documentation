require 'test_helper'

class ListingTest < ActiveSupport::TestCase

  setup do
    stub_mixpanel
    @listing = FactoryGirl.create(:listing)
    @user = FactoryGirl.create(:user)
    @platform_context = PlatformContext.new
    @platform_context.stubs(:instance).returns(Instance.default_instance)
    @subject = "#{@user.name} has shared a listing with you on #{@platform_context.decorate.name}"
  end

  test "#share" do
    mail = ListingMailer.share(@platform_context, @listing, 'jimmy@test.com', 'Jimmy Falcon', @user, 'Check this out!')

    assert_equal @subject, mail.subject
    assert mail.html_part.body.include?(@user.name)
    assert mail.html_part.body.include?('They also wanted to say:')
    assert mail.html_part.body.include?('Check this out!')

    assert_equal ['jimmy@test.com'], mail.to
  end

  test "#share without message" do
    mail = ListingMailer.share(@platform_context, @listing, 'jimmy@test.com', 'Jimmy Falcon', @user)

    assert_equal @subject, mail.subject
    assert mail.html_part.body.include?(@user.name)
    refute mail.html_part.body.include?('They also wanted to say:')

    assert_equal ['jimmy@test.com'], mail.to
  end
end

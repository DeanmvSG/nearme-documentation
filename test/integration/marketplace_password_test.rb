require "test_helper"

class MarketplacePasswordTest < ActionDispatch::IntegrationTest

  setup do
    @user = FactoryGirl.create(:user)
    stub_mixpanel
    @instance = Instance.first
    @role = FactoryGirl.create(:instance_admin_role)
    @role.update_attribute(:permission_analytics, false)
    @role.update_attribute(:permission_settings, true)
    @instance_admin = FactoryGirl.create(:instance_admin, :user_id => @user.id, :instance_id => @instance.id)
    @instance_admin.update_attribute(:instance_owner, false)
    @instance_admin.update_attribute(:instance_admin_role_id, @role.id)
  end

  should 'not redirect to marketplace password page if marketplace is not password-protected' do
    get_via_redirect root_path
    assert_equal root_path, path
  end

  should 'redirect to marketplace password page if marketplace is password-protected' do
    @instance.password_protected = true
    @instance.marketplace_password = '123'
    @instance.save!

    get_via_redirect root_path
    assert_equal new_marketplace_session_path, path
  end

  should 'not redirect to marketplace password page if previously authenticated' do
    @instance.password_protected = true
    @instance.marketplace_password = '123'
    @instance.save!

    get_via_redirect root_path
    post_via_redirect marketplace_sessions_path, password: '123'
    get_via_redirect root_path
    assert_equal root_path, path
  end

  should 'redirect to marketplace password page if wrong password given' do
    @instance.password_protected = true
    @instance.marketplace_password = '123'
    @instance.save!

    get_via_redirect root_path
    post_via_redirect marketplace_sessions_path, password: 'wrong'
    assert_equal marketplace_sessions_path, path
    assert_equal flash[:error], 'Wrong password!'
  end

  should 'not redirect to marketplace password page if requesting instance_admin' do
    @instance.password_protected = true
    @instance.marketplace_password = '123'
    @instance.save

    get_via_redirect instance_admin_path
    assert_equal instance_admin_login_path, path
  end

end


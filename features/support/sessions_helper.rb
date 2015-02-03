module SessionsHelper

  def login(user)
    auth = user.authentications.where(provider: 'twitter').first_or_initialize
    if auth.new_record?
      auth.uid = FactoryGirl.attributes_for(:authentication)[:uid]
      auth.token = FactoryGirl.attributes_for(:authentication)[:token]
    end
    auth.save!
    OmniAuth.config.add_mock(:twitter, {:uid => auth.uid, :credentials => {:token => auth.token}})
    visit "/auth/twitter"
  end

  def login_manually(email='valid@example.com', password = 'password')
    visit new_user_session_path
    fill_credentials(email, password)
    click_button "Log In"
  end

  def fill_credentials(email='valid@example.com', password = 'password')
    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
  end

  def login_with_provider(provider)
    visit new_user_session_path
    work_in_modal do
      click_link authentication_link_text_for_provider(provider)
    end
  end

  def log_out
    visit root_path
    find('.user-dropdown').click
    click_link 'Log Out'
  end
end
World(SessionsHelper)

# frozen_string_literal: true
And('the instance is a community instance') do
  @user = model!('the user')
  @user.save

  User.any_instance.stubs(:can_update_feed_status?).returns(true)

  @instance = PlatformContext.current.instance
  @instance.update_attribute(:is_community, true)
  @instance.default_profile_type.custom_attributes << FactoryGirl.build(:custom_attribute, name: 'role')

  query_string = <<EOQ
query TransactableCoverPhotoQuery($transactable_id: ID!){
  transactable(id: $transactable_id) {
    cover_photos: custom_attribute_photos(name: "cover_photo"){
      url: url(version: "normal")
    }
  }
}
EOQ
  @instance.graph_queries.create!(
    name: 'transactable_cover_photos',
    query_string: query_string
  )
end

And(/^a project with name: "(.*?)"$/) do |name|
  @project = FactoryGirl.create(:project, name: name)
end

And(/^a topic with name: "(.*?)"$/) do |name|
  @topic = FactoryGirl.create(:topic, name: name)
end

When(/^I visit another user page$/) do
  @resource = @another_user = FactoryGirl.create(:user)
  @resource_path = user_path(@resource)
  visit user_path(@another_user)
end

When(/^I visit another user page with status updates$/) do
  @resource = @another_user = FactoryGirl.create(:user)
  @resource_path = user_path(@resource)
  @another_user.user_status_updates.create('text' => 'This is the status update XYZ', 'topic_ids' => [''], 'updateable_id' => @another_user.id, 'updateable_type' => 'User')
  visit user_path(@another_user)
end

Then(/^I should see the user status update (.+)$/) do |status|
  page.body.should have_content(status)
end

Then(/^I should see the project status update (.+)$/) do |status|
  page.body.should have_content(status)
end

Then(/^I can see and press "(.*?)" button$/) do |name|
  event = name.downcase
  i18n_key = "activity_feed.verbs.#{event}"
  page.body.should have_content(I18n.t(i18n_key))
  send(event)
end

Then(/^I should be following it$/) do
  visit @resource_path
  page.body.should have_content(I18n.t('activity_feed.verbs.unfollow'))
end

Then(/^I should see the event on the user's Activity Feed$/) do
  @event = I18n.t('activity_feed.events.user_followed_user', follower: @user, followed: @another_user)
  page.body.should have_content(@event)
end

Then(/I can see user created project event/) do
  @event = I18n.t('activity_feed.events.user_created_transactable', user: @project.creator, project: @project)
  page.body.should have_content(@event)
end

Then(/^I should see the event on my Activity Feed$/) do
  visit user_path(@user)
  page.body.should have_content(@event)
end

Then(/^I shouldn't be following it anymore$/) do
  subscriptions = ActivityFeedSubscription.where(follower: @user, followed: @resource)
  subscriptions.count.should == 0
end

When(/^I visit project page$/) do
  @resource = @project
  @resource_path = @project.decorate.show_path
  visit @resource_path
end

When(/^I visit project page with status$/) do
  @resource = @project
  @resource_path = @project.decorate.show_path
  @project.creator.user_status_updates.create('text' => 'This is the project status XYZZ', 'topic_ids' => [''], 'updateable_id' => @project.id, 'updateable_type' => 'Transactable')
  visit @resource_path
end

Then(/^I should see the event on the followed project's Activity Feed$/) do
  @event = I18n.t('activity_feed.events.user_followed_project', follower: @user, followed: @resource)
  page.body.should have_content(@event)
end

When(/^I visit topic page$/) do
  @resource = @topic
  @resource_path = topic_path(@topic)
  visit @resource_path
end

Then(/^I should see the topic created event$/) do
  @event = I18n.t('activity_feed.events.topic_created', topic: @resource)
  page.body.should have_content(@event)
end

Then(/^I should see the event on the followed topic's Activity Feed$/) do
  @event = I18n.t('activity_feed.events.user_followed_topic', follower: @user, followed: @resource)
  page.body.should have_content(@event)
end

When(/^I'm on Hallmark marketplace$/) do
  instance = PlatformContext.current.instance
  instance.is_community = true
  instance.prepend_view_path = 'hallmark'
  instance.save!
end

Then(/^I can fill status update and add picture and submit it$/) do
  @text = "This is a status update for #{@resource.class.name}!"
  page.execute_script("document.querySelector('.CodeMirror').CodeMirror.setValue('#{@text}');")
  attach_file find('#new_user_status_update input[type="file"]', visible: false)[:name], File.join(Rails.root, 'test', 'assets', 'foobear.jpeg')
  click_button I18n.t('activity_feed.user_status_submit')
end

Then(/^I can create a new comment and add picture and submit it$/) do
  @text = "This is a comment\n"
  within("article[data-activity-feed-event-id='#{ActivityFeedEvent.last.id}'] #new_comment") do
    attach_file find('[data-user-entry-form-file]', visible: false)[:name], File.join(Rails.root, 'test', 'assets', 'foobear.jpeg')
    find('textarea').set(@text)
  end
end

Then(/^I can see the comment on the Activity Feed with picture$/) do
  page.should have_content(@text)
  page.should have_css("#entry-content-comment-#{Comment.last.id} div.entry-images img")
  assert_equal 1, Comment.last.activity_feed_images.count
end

Then(/^I can see the event on the Activity Feed with picture$/) do
  i18n_key = "activity_feed.events.user_updated_#{@resource.class.name.downcase}_status"
  @resource = '' if @resource == @user
  @event = I18n.t(i18n_key, user: @user, updated: @resource)

  page.should have_content(@event)
  page.should have_css("#entry-content-user-status-#{UserStatusUpdate.last.id} div.entry-images img")
  page.should have_content(@text)
  assert_equal 1, UserStatusUpdate.last.activity_feed_images.count
end

Then(/^I can see the edited event on the Activity Feed (with|without) picture/) do |picture_presence|
  page.should have_content(@new_text)
  page.should_not have_content(@text)
  if picture_presence == 'with'
    page.should have_css("#entry-content-user-status-#{UserStatusUpdate.last.id} div.entry-images img")
    assert_equal 1, UserStatusUpdate.last.activity_feed_images.count
    assert ActivityFeedImage.last.image.to_s.include?('bully.jpeg')
  else
    page.should_not have_css("#entry-content-user-status-#{UserStatusUpdate.last.id} div.entry-images img")
    assert_equal 0, UserStatusUpdate.last.activity_feed_images.count
  end
end

Then(/^I can see the edited comment on the Activity Feed (with|without) picture/) do |picture_presence|
  page.should have_content(@new_text)
  page.should_not have_content(@text)
  if picture_presence == 'with'
    page.should have_css("#entry-content-comment-#{Comment.last.id} div.entry-images img")
    assert_equal 1, Comment.last.activity_feed_images.count
    assert ActivityFeedImage.last.image.to_s.include?('bully.jpeg')
  else
    page.should_not have_css("#entry-content-comment-#{Comment.last.id} div.entry-images img")
    assert_equal 0, Comment.last.activity_feed_images.count
  end
end

Then(/^I can edit the event and add new image$/) do
  @status_update = UserStatusUpdate.last
  page.find("#status-update-actions-#{@status_update.id} > button").click
  page.find("#status-update-actions-#{@status_update.id} > ul > li.edit-action > a").click
  @new_text = 'New text of status'
  page.execute_script("document.querySelector('#edit_user_status_update_#{@status_update.id} .CodeMirror').CodeMirror.setValue('#{@new_text}');")
  within("#edit_user_status_update_#{@status_update.id}") do
    attach_file find('input[type="file"]')[:name], File.join(Rails.root, 'test', 'assets', 'bully.jpeg')
    find('[type="submit"]').click
  end
end

Then(/^I can edit the comment and add new image$/) do
  @comment = Comment.last
  page.find("#comment-actions-#{@comment.id} > button").click
  page.find("#comment-actions-#{@comment.id} > ul > li.edit-action > a").click
  @new_text = 'New text of comment'
  page.find("#edit_comment_#{@comment.id} textarea").set(@new_text)
  within("#edit_comment_#{@comment.id}") do
    attach_file find('input[type="file"]')[:name], File.join(Rails.root, 'test', 'assets', 'bully.jpeg')
    find('[type="submit"]').click
  end
end

Then(/I edit the event and delete image$/) do
  status_update = UserStatusUpdate.last
  page.find("#status-update-actions-#{@status_update.id} > button").click
  page.find("#status-update-actions-#{@status_update.id} > ul > li.edit-action > a").click
  within("#edit_user_status_update_#{@status_update.id}") do
    find('button.remove').click
    find('[type=submit]').click
    sleep(1)
  end
end

Then(/I edit the comment and delete image$/) do
  @comment = Comment.last
  page.find("#comment-actions-#{@comment.id} > button").click
  page.find("#comment-actions-#{@comment.id} > ul > li.edit-action > a").click
  within("#edit_comment_#{@comment.id}") do
    find('button.remove').click
    find("[type='submit']").click
  end
end

When(/^I have status update created$/) do
  UserStatusUpdate.create!(user: @user, text: 'Text of status update', updateable: @user)
end

When(/^I visit my page$/) do
  @resource = @user
  visit user_path(@user)
end

Then(/^I can fill status update and submit it$/) do
  @text = "This is a status update for #{@resource.class.name}!"
  page.find('#user_status_update_text').set(@text)
  click_button I18n.t('activity_feed.user_status_submit')
end

Then(/^I can see the event on the Activity Feed$/) do
  i18n_key = "activity_feed.events.user_updated_#{@resource.class.name.downcase}_status"
  @resource = '' if @resource == @user
  @event = I18n.t(i18n_key, user: @user, updated: @resource)

  page.should have_content(@event)
  page.should have_content(@text)
end

And(/^I shouldn't see report as spam button$/) do
  page.text.should_not have_content(I18n.t(:report_as_spam))
end

def follow
  visit @resource_path
  page.find('[data-follow-button] a').click
  wait_for_ajax
  visit user_path(@user)
end

def unfollow
  visit @resource_path
  page.find('[data-follow-button] a').click
  wait_for_ajax
  visit user_path(@user)
end

require 'test_helper'

class ActivityFeedServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @feed = ActivityFeedService.new(@user)
  end

  context "instance methods" do
    should "#events" do
      followed1 = create(:user)
      followed2 = create(:user)
      follower1 = create(:user)
      project1  = create(:project)

      assert_equal 0, @feed.events.count

      # Following actions
      #
      @user.feed_follow!(followed1)
      assert_equal 1, @feed.events.count

      @user.feed_follow!(followed2)
      assert_equal 2, @feed.events.count

      # Even if someone follows an user, we don't want to
      # display on user's feed.
      #
      follower1.feed_follow!(@user)
      assert_equal 3, @feed.events.count

      # User can also follow projects here we jump to five
      # because there's the project creation event and the action of
      # following the project.
      #
      # The last - first in chronology - event should be user_created_project
      # because the project was created before this user following anyone
      #
      # The first - last in chronology - event should be user following project
      # because he followed everyone afterwards.
      #

      @user.feed_follow!(project1)
      assert @feed.events.first.event.to_sym  == :user_followed_project

      assert_equal 4, @feed.events.count

      # You can unfollow users - but events aren't deleted from your
      # timeline.
      #
      @user.feed_unfollow!(followed1)
      assert_equal 4, @feed.events.count

      @user.feed_unfollow!(followed2)
      assert_equal 4, @feed.events.count

      # Pagination testing - we'd only want to display the amount of events
      # that was requested.
      #

      ActivityFeedService::EVENTS_PER_PAGE.times { create(:user) }
      User.first(ActivityFeedService::EVENTS_PER_PAGE).each { |followed| @user.feed_follow!(followed) }
      # On the first page are the new 20 user_followed_user events
      # and on the second, the first 5.
      #
      assert_equal 20, @feed.events.count
      assert_equal 2, @feed.events({page: 2}).count
    end

    should "#owner_id" do
      assert @user.id == @feed.owner_id
    end

    should "#owner_type" do
      assert @user.class.name == @feed.owner_type
    end
  end

  context "class methods" do
    should ".create_event" do
      followed = create(:user)

      # It should create a new event.
      #
      assert_difference 'ActivityFeedEvent.count' do
        ActivityFeedService.create_event(
          :user_followed_user,
          followed,
          [followed],
          @user
        )
      end

      # If an event has the same exact aspects (event, followed and event_source),
      # a new event shouldn't be created
      count = ActivityFeedEvent.count

      3.times do
        ActivityFeedService.create_event(
          :user_followed_user,
          followed,
          [followed],
          @user
        )
      end

      assert_equal count, ActivityFeedEvent.count
    end
  end
end

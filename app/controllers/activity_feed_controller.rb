class ActivityFeedController < ApplicationController
  before_filter :set_object_with_followed_whitelist
  before_filter :authenticate_user!, only: [:follow, :unfollow]

  # "Follow/Unfollow" feature section
  #
  # Parameters that should be provided:
  # Mandatory:
  # id              |  The id of the object which should be followed
  # type            |  The type of the object that should be followed

  def follow
    current_user.feed_follow!(@object)
    @followers_count = @object.feed_followers.count
    respond_to do |format|
      format.js { render :follow_and_unfollow }
    end
  end

  def unfollow
    current_user.feed_unfollow!(@object)
    @followers_count = @object.feed_followers.count
    respond_to do |format|
      format.js { render :follow_and_unfollow }
    end
  end


  # "See more" feature section
  #
  # Parameters that should be provided:
  # Mandatory:
  # page            |  The current page we're in
  # id              |  The object which dictates the scope of the query
  # type            |  The type of the resource we should find.
  #
  # Optionals:
  # containter      |  The container to append the new results

  def activity_feed
    @container = params[:container].presence || "#activity"

    options = {}
    options.merge!(user_feed: true) if params[:type] == 'User'

    @feed = ActivityFeedService.new(@object, options)

    @partial = "shared/activity_status"
    @as = :event
    @collection = @feed.events(pagination_params.merge(per_page: ActivityFeedService::Helpers::EVENTS_PER_PAGE))

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  def following_people
    @container = params[:container].presence || "#following-people"

    @partial = "shared/person"
    @as = :user
    @collection = @object.feed_followed_users.custom_order(params[:sort], current_user).paginate(pagination_params)

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  def following_projects
    @container = params[:container].presence || "#following-projects"

    @partial = "shared/project"
    @as = :project
    @collection = @object.feed_followed_projects.enabled.custom_order(params[:sort]).paginate(pagination_params)

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  def following_topics
    @container = params[:container].presence || "#following-topics"

    @partial = "shared/topic"
    @as = :topic
    @collection = @object.feed_followed_topics.paginate(pagination_params)

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  def followers
    @container = params[:container].presence || "#followers"

    @partial = "shared/person"
    @as = :user
    @collection = @object.feed_followers.custom_order(params[:sort], current_user).paginate(pagination_params)

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  def projects
    @container = params[:container].presence || "#projects"

    @partial = "shared/project"
    @as = :project
    @collection = @object.all_projects.enabled.custom_order(params[:sort]).paginate(pagination_params)

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  def collaborators
    @container = params[:container].presence || "#collaborators"

    @partial = "shared/person"
    @as = :user
    @collection = @object.collaborating_users.custom_order(params[:sort], current_user).paginate(pagination_params)

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  def members
    @container = params[:container].presence || "#members"

    @partial = "shared/person"
    @as = :user
    @collection = @object.approved_members.custom_order(params[:sort], current_user).paginate(pagination_params)

    respond_to do |format|
      format.js { render :see_more }
    end
  end

  private

  def set_object(whitelist)
    @id, @type = params[:id], params[:type].try(:gsub, "Decorator", "")
    render json: {}, status: 422 && return if !@id.present? && !@type.present?

    if whitelist.include?(@type)
      @object = @type.constantize.find(@id)
    else
      render json: {}, status: 422 && return
    end
  end

  def set_object_with_followed_whitelist
    set_object(ActivityFeedService::Helpers::FOLLOWED_WHITELIST)
  end

  def pagination_params
    {
      page: params[:page].to_i > 0 ? params[:page] : 1,
      per_page: ActivityFeedService::Helpers::FOLLOWED_PER_PAGE
    }
  end
end

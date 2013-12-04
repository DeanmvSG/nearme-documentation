# Our internal wrapper for Mixpanel calls.
#
# Provides an internal interface for triggering Mixpanel calls
# with the correct user data, persisted properties, etc.
#
# Controller requests should initialize this object and pass through
# the relevant session details.
#
# Upon completion of requests, controllers should persist any required
# attributes (i.e. anonymous_identity, session_properties) which should
# be passed back a new instance of this wrapper on subsequent requests.
class AnalyticWrapper::MixpanelApi
  # The user form whom the current session represents.
  # This will be used for the mixpanel id.
  attr_reader :current_user

  # If no user is available, then we need an anonymous identity to
  # log events as. This will be generated automatically, or can be
  # provided if it has already been persisted from another session.
  attr_reader :anonymous_identity

  # Hash of session properties that are applied globally to any
  # triggered events.
  attr_reader :session_properties

  # Hash of additional request information that are applied globally to any
  # triggered events.
  attr_reader :request_details

  # Request object passed from controller
  attr_reader :request

  # Creates a new mixpanel API interface instance
  def self.mixpanel_instance(options = {})
    Mixpanel::Tracker.new(DesksnearMe::Application.config.mixpanel[:token], options)
  end

  # Initialize a mixpanel wrapper.
  #
  # mixpanel - The basic mixpanel API object
  # options  - A set of additional options relevant to our setup
  #            current_user - The current user object, if the user is logged in.
  #            request_details - Hash with important tracking information like Id of Instance that was used, request host
  #            anonymous_identity - The current anonymous identifier, if any.
  #            session_properties - Hash of persisted global properties to apply to
  #                                 all events.
  #
  def initialize(mixpanel, options = {})
    @mixpanel = mixpanel
    @current_user = options[:current_user]
    @anonymous_identity = options[:anonymous_identity] || (generate_anonymous_identity unless @current_user)
    @session_properties = (options[:session_properties] || {}).with_indifferent_access
    @request_details = (options[:request_details] || {}).with_indifferent_access
    @request = options[:request]

    extract_properties_from_params(options[:request_params])
  end

  # Assigns a user to this tracking instance, clearing any 'anonymous' state
  def apply_user(user, options = { :alias => false })
    @current_user = user

    # If we're currently an anonymous identity, we need to alias that
    # to the user user.
    if options[:alias] && anonymous_identity
      MixpanelApiJob.perform(@mixpanel, :alias, distinct_id, { :distinct_id => anonymous_identity })
      Rails.logger.info "Aliased mixpanel user: #{anonymous_identity} is now #{distinct_id}"
    end

    @anonymous_identity = nil
  end

  # Track an event against the user in the current session.
  def track(event_name, properties, options = {})
    # Assign the user ID for this session
    properties = properties.reverse_merge(
      :distinct_id => distinct_id
    )

    # Assign any global properties
    properties.reverse_merge!(session_properties)
    properties.reverse_merge!(request_details)

    if requested_by_bot?
      Rails.logger.info "Bot detected! Not tracking mixpanel event: #{event_name}, #{properties}, #{options}"
    else
      # Trigger tracking the event
      MixpanelApiJob.perform(@mixpanel, :track, event_name, properties, options)
      Rails.logger.info "Tracked mixpanel event: #{event_name}, #{properties}, #{options}"
    end
  end

  def pixel_track_url(event_name, properties, options = {})
    properties = properties.reverse_merge(
      :distinct_id => distinct_id
    )

    # Assign any global properties
    properties.reverse_merge!(session_properties)
    properties.reverse_merge!(request_details)

    
    Rails.logger.info "Pixel based tracking mixpanel event: #{event_name}, #{properties}, #{options}"
    "<img src='#{@mixpanel.tracking_pixel(event_name, properties, options)}' width='1' height='1'>"
  end

  # Sets global Person properties on the current tracked session.
  def set_person_properties(properties)
    MixpanelApiJob.perform(@mixpanel, :set, distinct_id, properties)
    Rails.logger.info "Set mixpanel person properties: #{distinct_id}, #{properties}"
  end

  # Track a charge against the user in the current session, incurring the
  # specified revenue for us.
  def track_charge(amount)
    MixpanelApiJob.perform(@mixpanel, :track_charge, distinct_id, amount)
    Rails.logger.info "Tracked charge: user #{distinct_id}, amount: #{amount}$"
  end

  # Returns the distinct ID for the user of the current session.
  def distinct_id
    current_user.try(:id) || anonymous_identity
  end

  def requested_by_bot?
    @request && @request.bot?
  end

  private

  def generate_anonymous_identity
    SecureRandom.hex(8)
  end

  # Extracts special properties from request parameters. These properties are
  # treated as session/global properties that persist between user requests.
  #
  # We mainly use this to track the request source/campaign.
  def extract_properties_from_params(params)
    return unless params

    [:source, :campaign].each do |param|
      @session_properties[param] = params[param] if params[param]
    end
  end

end

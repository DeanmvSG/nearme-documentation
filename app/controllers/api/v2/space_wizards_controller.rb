module Api
  class V2::SpaceWizardsController < BaseController
    skip_before_filter :require_authorization
    before_filter :find_transactable_type
    before_filter :set_common_variables
    before_filter :sanitize_price_parameters

    include AttachmentsHelper

    # see no evil :(
    def create
      params[:user][:companies_attributes]['0'][:name] = current_user.first_name if platform_context.instance.skip_company? && params[:user][:companies_attributes]['0'][:name].blank?
      set_listing_draft_timestamp(params[:save_as_draft] ? Time.zone.now : nil)
      set_proper_currency
      @user.get_seller_profile
      @user.skip_validations_for = [:buyer]
      @user.must_have_verified_phone_number = true if @user.requires_mobile_number_verifications?
      @user.assign_attributes(wizard_params)

      @user.companies.first.creator = current_user
      build_objects
      build_approval_requests
      @user.first_listing.creator = @user
      if params[:save_as_draft]
        remove_approval_requests
        @user.valid? # Send .valid? message to object to trigger any validation callbacks
        @user.companies.first.update_metadata(draft_at: Time.now, completed_at: nil)
        if @user.first_listing.new_record?
          @user.save(validate: false)
          fix_availability_templates
          track_saved_draft_event
          WorkflowStepJob.perform(WorkflowStep::ListingWorkflow::DraftCreated, @user.first_listing.id)
        else
          @user.save(validate: false)
        end
        render json: ApiSerializer.serialize_object(@user.first_listing)
      elsif @user.save
        @user.listings.first.action_type.try(:schedule).try(:create_schedule_from_schedule_rules)
        @user.companies.first.update_metadata(draft_at: nil, completed_at: Time.now)
        track_new_space_event
        track_new_company_event

        WorkflowStepJob.perform(WorkflowStep::ListingWorkflow::PendingApproval, @user.first_listing.id) unless @user.first_listing.is_trusted?
        WorkflowStepJob.perform(WorkflowStep::ListingWorkflow::Created, @user.first_listing.id)
        render json: ApiSerializer.serialize_object(@user.first_listing)
      else
        render json: ApiSerializer.serialize_errors(@user.errors)
      end
    end

    private

    # When saving drafts we end up with parent_type = nil for custom availability templates causing problems down the line
    def fix_availability_templates
      listing = @user.companies.first.locations.first.listings.first
      return unless listing.time_based_booking
      availability_template = listing.time_based_booking.availability_template
      if availability_template
        if availability_template.try(:parent_type) == 'Transactable::TimeBasedBooking' && availability_template.try(:parent_id).nil?
          availability_template.parent = listing.time_based_booking
          availability_template.save(validate: false)
        end
      else
        listing.time_based_booking.update(availability_template: @transactable_type.default_availability_template)
      end
    end

    def remove_approval_requests
      @user.approval_requests = []
      @user.companies.first.approval_requests = []
      @user.companies.first.locations.first.listings.first.approval_requests = []
    end

    def find_transactable_type
      @transactable_type = TransactableType.includes(:custom_attributes).friendly.find(params[:transactable_type_id])
    end

    def set_form_components
      @form_components = @transactable_type.form_components.where(form_type: FormComponent::SPACE_WIZARD).rank(:rank)
    end

    def set_common_variables
      redirect_to(transactable_type_new_space_wizard_url(@transactable_type)) && return unless current_user.present?

      # preload associations to correcty make #assign_attributes work correctly
      @user = User.includes(companies: :locations).find(current_user.id)
      @company = @user.companies.first
      @country = if params[:user] && params[:user][:country_name]
                   params[:user][:country_name]
                 elsif @user.country_name.present?
                   @user.country_name
                 else
                   request.location.country rescue nil
                 end
    end

    def build_objects
      @user.companies.build if @user.companies.first.nil?
      @user.companies.first.locations.build if @user.companies.first.locations.first.nil?
      @user.companies.first.locations.first.transactable_type = @transactable_type
      @transactable = @user.companies.first.locations.first.listings.first || @user.companies.first.locations.first.listings.build(transactable_type_id: @transactable_type.id, booking_type: @transactable_type.booking_choices.first)
      @transactable.attachment_ids = attachment_ids_for(@transactable) if params.key?(:attachment_ids)
    end

    def redirect_to_dashboard_if_registration_completed
      if current_user.try(:registration_completed?)
        redirect_to dashboard_company_transactable_type_transactables_path(@transactable_type)
      end
    end

    def track_saved_draft_event
      event_tracker.saved_a_draft
    end

    def track_new_space_event
      @location = @user.locations.first
      @listing = @user.listings.first
      event_tracker.created_a_location(@location, via: 'wizard')
      event_tracker.created_a_listing(@listing, via: 'wizard')
      event_tracker.updated_profile_information(@user)
    end

    def track_new_company_event
      @company = @user.companies.first
      event_tracker.created_a_company(@company) unless platform_context.instance.skip_company?
    end

    def set_proper_currency
      params[:user][:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'][:currency] = params[:user][:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'][:currency].presence || PlatformContext.current.instance.default_currency
    rescue
      nil
    end

    def set_listing_draft_timestamp(timestamp)
      params[:user][:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'][:draft] = timestamp
      params[:user][:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'][:enabled] = true
    rescue
      nil
    end

    def sanitize_price_parameters
      params[:user][:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'].select { |k, _v| k.include?('_price') }.each do |k, v|
        params[:user][:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'][k] = v.to_f unless v.blank?
      end
    rescue
    end

    def wizard_params
      params.require(:user).permit(secured_params.user(transactable_type: @transactable_type)).tap do |whitelisted|
        (whitelisted[:seller_profile_attributes][:properties] = params[:user][:seller_profile_attributes][:properties]) rescue {}
        (whitelisted[:properties] = params[:user][:properties]) rescue {}
        (whitelisted[:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'][:properties] = params[:user][:companies_attributes]['0'][:locations_attributes]['0'][:listings_attributes]['0'][:properties]) rescue {}
      end
    end

    def build_approval_requests
      build_approval_request_for_object(@user)
      build_approval_request_for_object(@user.companies.first)
      build_approval_request_for_object(@user.companies.first.locations.first.listings.first)
    end
  end
end

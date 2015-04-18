class TransactableTypes::SpaceWizardController < ApplicationController

  before_filter :find_transactable_type
  before_filter :redirect_to_dashboard_if_registration_completed, only: [:new, :list]
  before_filter :set_form_components
  before_filter :set_common_variables, :only => [:list, :submit_listing]
  before_filter :sanitize_price_parameters, :only => [:submit_listing]
  before_filter :set_theme, :only => [:list, :submit_item]

  def new
    flash.keep(:warning)
    event_tracker.clicked_list_your_bookable({source: request.referer ? URI(request.referer).path : "direct"})
    if current_user
      redirect_to transactable_type_space_wizard_list_path(@transactable_type)
    else
      redirect_to new_user_registration_url(:wizard => 'space', :return_to => transactable_type_space_wizard_list_url(@transactable_type))
    end
  end

  def list
    build_objects
    build_approval_requests
    @photos = (@user.first_listing.try(:photos) || []) + @user.photos.where(transactable_id: nil)
    @user.phone_required = true
    event_tracker.viewed_list_your_bookable
    event_tracker.track_event_within_email(current_user, request) if params[:track_email_event]
  end

  def submit_listing
    @user.phone_required = true
    params[:user][:companies_attributes]["0"][:name] = current_user.name if platform_context.instance.skip_company? && params[:user][:companies_attributes]["0"][:name].blank?
    set_listing_draft_timestamp(params[:save_as_draft] ? Time.zone.now : nil)
    @user.assign_attributes(wizard_params)
    @user.companies.first.try(:locations).try(:first).try {|l| l.name_and_description_required = true}
    @user.companies.first.creator = current_user
    build_objects
    build_approval_requests
    if params[:save_as_draft]
      remove_approval_requests
      @user.valid? # Send .valid? message to object to trigger any validation callbacks
      if @user.first_listing.new_record?
        @user.save(validate: false)
        track_saved_draft_event
        WorkflowStepJob.perform(WorkflowStep::ListingWorkflow::DraftCreated, @user.first_listing.id)
      else
        @user.save(validate: false)
      end
      flash[:success] = t('flash_messages.space_wizard.draft_saved')
      redirect_to transactable_type_space_wizard_list_path(@transactable_type)
    elsif @user.save
      track_new_space_event
      track_new_company_event
      WorkflowStepJob.perform(WorkflowStep::ListingWorkflow::Created, @user.first_listing.id)
      flash[:success] = t('flash_messages.space_wizard.space_listed', bookable_noun: @transactable_type.name)
      flash[:error] = t('manage.listings.no_trust_explanation') if @user.listings.first.present? && !@user.listings.first.is_trusted?
      redirect_to dashboard_company_transactable_type_transactables_path(@transactable_type)
    else
      @photos = @user.first_listing ? @user.first_listing.photos : nil
      flash.now[:error] = t('flash_messages.space_wizard.complete_fields') + view_context.array_to_unordered_list(filter_error_messages(@user.errors.full_messages))
      render :list
    end
  end

  private

  def filter_error_messages(messages)
    pattern = /^Companies locations listings photos /
    messages.collect do |message|
      if message.to_s.match(pattern)
        message.to_s.gsub(pattern, '')
      else
        message
      end
    end
  end

  def find_transactable_type
    @transactable_type = TransactableType.includes(:custom_attributes).find(params[:transactable_type_id])
  end

  def set_form_components
    @form_components = @transactable_type.form_components.where(form_type: FormComponent::SPACE_WIZARD).rank(:rank)
  end

  def set_common_variables
    redirect_to(transactable_type_new_space_wizard_url(@transactable_type)) && return unless current_user.present?

    @user = current_user
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
    @user.companies.first.locations.first.listings.build({:transactable_type_id => @transactable_type.id}) if @user.companies.first.locations.first.listings.first.nil?
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
    event_tracker.created_a_location(@location , { via: 'wizard' })
    event_tracker.created_a_listing(@listing, { via: 'wizard' })
    event_tracker.updated_profile_information(@user)
  end

  def track_new_company_event
    @company = @user.companies.first
    event_tracker.created_a_company(@company) unless platform_context.instance.skip_company?
  end

  def set_transactable_type_id
    params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"][:transactable_type_id] = @transactable_type.id
  end

  def set_listing_draft_timestamp(timestamp)
    begin
      params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"][:draft] = timestamp
      params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"][:enabled] = true
    rescue
      nil
    end
  end

  def sanitize_price_parameters
    begin
      params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"].select { |k, v| k.include?('_price') }.each do |k, v|
        params[:user][:companies_attributes]["0"][:locations_attributes]["0"][:listings_attributes]["0"][k] = v.to_f unless v.blank?
      end
    rescue
      # no need to do anything
    end
  end

  def wizard_params
    params.require(:user).permit(secured_params.user)
  end

  def boarding_form_params
    params.require(:boarding_form).permit(secured_params.boarding_form(@product_type))
  end

  def build_approval_requests
    build_approval_request_for_object(@user)
    build_approval_request_for_object(@user.companies.first)
    build_approval_request_for_object(@user.companies.first.locations.first)
    build_approval_request_for_object(@user.companies.first.locations.first.listings.first)
  end

  def can_delete_photo?(photo, user)
    return true if photo.creator == user                         # if the user created the photo
    return true if photo.listing.administrator == user    # if the user is an admin of the photos content
    return true if user.companies.first.listings.include?(photo.listing)     # if the photo content is a listing and belongs to company
  end

  def set_theme
    @theme_name = 'product-theme'
  end

  def remove_approval_requests
    @user.approval_requests = []
    @user.companies.first.approval_requests = []
    @user.companies.first.locations.first.approval_requests = []
    @user.companies.first.locations.first.listings.first.approval_requests = []
  end

end


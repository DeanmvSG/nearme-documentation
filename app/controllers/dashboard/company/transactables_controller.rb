class Dashboard::Company::TransactablesController < Dashboard::Company::BaseController
  before_filter :find_transactable_type
  before_filter :find_transactable, :except => [:index, :new, :create]
  before_filter :find_locations
  before_filter :disable_unchecked_prices, :only => :update
  before_filter :set_form_components

  def index
    @transactables = @transactable_type.transactables.where(company_id: @company).paginate(page: params[:page], per_page: 20)
  end

  def new
    @transactable = @transactable_type.transactables.build company: @company
    @transactable.availability_template_id = @transactable_type.availability_templates.first.id
    build_approval_request_for_object(@transactable) unless @transactable.is_trusted?
    @photos = current_user.photos.where(transactable_id: nil)
    build_document_requirements_and_obligation if platform_context.instance.documents_upload_enabled?
  end

  def create
    @transactable = @transactable_type.transactables.build(transactable_params)
    @transactable.company = @company

    build_approval_request_for_object(@transactable) unless @transactable.is_trusted?
    if @transactable.save
      flash[:success] = t('flash_messages.manage.listings.desk_added', bookable_noun: @transactable_type.bookable_noun)
      event_tracker.created_a_listing(@transactable, { via: 'dashboard' })
      event_tracker.updated_profile_information(current_user)
      redirect_to dashboard_company_transactable_type_transactables_path(@transactable_type)
    else
      flash.now[:error] = t('flash_messages.space_wizard.complete_fields') + view_context.array_to_unordered_list(@transactable.errors.full_messages)
      @photos = @transactable.photos
      render :new
    end
  end

  def show
    redirect_to action: :edit
  end

  def edit
    @photos = @transactable.photos
    build_approval_request_for_object(@transactable) unless @transactable.is_trusted?
    event_tracker.track_event_within_email(current_user, request) if params[:track_email_event]
    build_document_requirements_and_obligation if platform_context.instance.documents_upload_enabled?
  end

  def update
    @transactable.assign_attributes(transactable_params)
    build_approval_request_for_object(@transactable) unless @transactable.is_trusted?
    respond_to do |format|
      format.html {
        if @transactable.save
          flash[:success] = t('flash_messages.manage.listings.listing_updated')
          redirect_to dashboard_company_transactable_type_transactables_path(@transactable_type)
        else
          flash.now[:error] = t('flash_messages.space_wizard.complete_fields') + view_context.array_to_unordered_list(@transactable.errors.full_messages)
          @photos = @transactable.photos
          render :edit
        end
      }
      format.json {
        if @transactable.save
          render :json => { :success => true }
        else
          render :json => { :errors => @transactable.errors.full_messages }, :status => 422
        end
      }
    end
  end

  def enable
    if @transactable.enable!
      render :json => { :success => true }
    else
      render :json => { :errors => @transactable.errors.full_messages }, :status => 422
    end
  end

  def disable
    if @transactable.disable!
      render :json => { :success => true }
    else
      render :json => { :errors => @transactable.errors.full_messages }, :status => 422
    end
  end

  def destroy
    @transactable.reservations.each do |r|
      r.perform_expiry!
    end
    @transactable.destroy
    event_tracker.updated_profile_information(current_user)
    event_tracker.deleted_a_listing(@transactable)
    flash[:deleted] = t('flash_messages.manage.listings.listing_deleted')
    redirect_to dashboard_company_transactable_type_transactables_path(@transactable_type)
  end

  private

  def set_form_components
    @form_components = @transactable_type.form_components.where(form_type: FormComponent::TRANSACTABLE_ATTRIBUTES).rank(:rank)
  end

  def find_locations
    @locations = @company.locations
  end

  def find_transactable
    begin
      @transactable = @transactable_type.transactables.where(company_id: @company).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise Transactable::NotFound
    end
  end

  def disable_unchecked_prices
    Transactable::PRICE_TYPES.each do |price|
      if params[:transactable]["#{price}_price"].blank?
        @transactable.send("#{price}_price=", nil) if @transactable.respond_to?("#{price}_price_cents=")
      end
    end
  end

  def find_transactable_type
    @transactable_type = TransactableType.find(params[:transactable_type_id])
  end

  def transactable_params
    params.require(:transactable).permit(secured_params.transactable(@transactable_type))
  end

  def build_document_requirements_and_obligation
    @transactable.build_upload_obligation(level: UploadObligation::LEVELS.first) unless @transactable.upload_obligation
    DocumentRequirement::MAX_COUNT.times do
      hidden = @transactable.document_requirements.blank? ? "0" : "1"
      document_requirement = @transactable.document_requirements.build
      document_requirement.hidden = hidden
    end
  end
end

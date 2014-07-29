class PlatformHomeController < ActionController::Base
  before_filter :require_ssl
  prepend_view_path InstanceViewResolver.instance

  protect_from_forgery
  layout 'platform_home'

  def index
    if params[:domain_not_valid]
      flash[:error] = 'This domain has not been configured.'
      redirect_to '/'
    end
    @platform_contact = PlatformContact.new
  end

  def require_ssl
    if Rails.application.config.secure_app && !request.ssl?
      if request.get? # we can't redirect non-get reqests
        redirect_to url_for(protocol: 'https'), status: :moved_permanently
      else
        redirect_to root_url(protocol: 'https')
      end
    end
  end

  def contact
    @platform_contact = PlatformContact.new
  end

  def contact_submit
    @platform_contact = PlatformContact.new(params[:platform_contact])
    @platform_contact.referer = request.referer
    if verified_request? && @platform_contact.save
      PlatformMailer.enqueue.contact_request(@platform_contact)
      PlatformMailer.enqueue.email_notification(@platform_contact.email)
      render :contact_submit, layout: false
    else
      @platform_contact.errors.add(:CSRF_token, 'is invalid') if !verified_request?
      render text: @platform_contact.errors.full_messages.to_sentence, layout: false, :status => :unprocessable_entity
    end
  end

  def contacts
    @platform_contacts = PlatformContact.order(:id)
    respond_to do |format|
      format.csv { send_data @platform_contacts.to_csv }
    end
  end

  def demo_requests
    @platform_demo_requests = PlatformDemoRequest.order(:id)
    respond_to do |format|
      format.csv { send_data @platform_demo_requests.to_csv }
    end
  end

  def unsubscribe
    verifier = ActiveSupport::MessageVerifier.new(DesksnearMe::Application.config.secret_token)
    email_address = verifier.verify(params[:unsubscribe_key])
    @email = PlatformEmail.where('email = ?', email_address).first

    if @email
      @resubscribe_url = platform_email_resubscribe_url(params[:unsubscribe_key])
      @email.unsubscribe!
    else
      redirect_to '/'
    end
  end

  def resubscribe
    verifier = ActiveSupport::MessageVerifier.new(DesksnearMe::Application.config.secret_token)
    email_address = verifier.verify(params[:resubscribe_key])
    @email = PlatformEmail.where('email = ?', email_address).first

    if @email
      @email.resubscribe!
    else
      redirect_to '/'
    end
  end
end

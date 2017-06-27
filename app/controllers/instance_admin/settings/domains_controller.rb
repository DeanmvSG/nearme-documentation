require 'nearme/r53'

class InstanceAdmin::Settings::DomainsController < InstanceAdmin::Settings::BaseController
  before_action :find_domain, only: [:edit, :update, :destroy]

  def index
    @domains = DomainDecorator.decorate_collection(domains)
  end

  def show
    @domain = DomainDecorator.decorate(find_domain)
  end

  def new
    @domain = domains.new
  end

  def create
    @domain = domains.build(domain_params)
    if @domain.save
      if @domain.secured?
        @domain.prepare_elb!
        CreateElbJob.perform(@domain)
        flash[:success] = t('flash_messages.instance_admin.settings.domain_preparing')
      else
        flash[:success] = t('flash_messages.instance_admin.settings.domain_created')
      end
      redirect_to instance_admin_settings_domains_path
    else
      flash.now[:error] = @domain.errors.full_messages.to_sentence
      render :new
    end
  end

  def update
    @domain.assign_attributes(domain_params)

    elb_need_updating = @domain.aws_certificate_id_changed?

    if @domain.save
      UpdateElbJob.perform(@domain) if elb_need_updating

      flash[:success] = t('flash_messages.instance_admin.settings.settings_updated')
      redirect_to instance_admin_settings_domains_path
    else
      flash.now[:error] = @domain.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    Domain.transaction do
      if @domain.deletable? && @domain.destroy
        if @domain.load_balancer_name
          DeleteElbJob.perform(@domain.load_balancer_name)
        end
        flash[:success] = t('flash_messages.instance_admin.settings.domain_deleted')
      else
        flash[:error] = t('flash_messages.instance_admin.settings.domain_not_deleted')
      end
    end
  rescue
    flash[:error] = t('flash_messages.instance_admin.settings.domain_not_deleted')
  ensure
    redirect_to instance_admin_settings_domains_path
  end

  private

  def permitting_controller_class
    'AdministratorRestrictedAccess'
  end

  def domains
    @domains ||= @instance.domains
  end

  def find_domain
    @domain ||= @instance.domains.find(params[:id])
  end

  def domain_params
    params.require(:domain).permit(secured_params.domain)
  end
end
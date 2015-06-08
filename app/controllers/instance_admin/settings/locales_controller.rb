class InstanceAdmin::Settings::LocalesController < InstanceAdmin::Settings::BaseController
  before_filter :find_locale, except: [:index, :new, :create, :new_key, :create_key, :destroy_key]

  def index
    @locales = platform_context.instance.locales.order('created_at')
  end

  def new
    @locale = platform_context.instance.locales.build
  end

  def create
    @locale = platform_context.instance.locales.new(locale_params)

    if @locale.save
      flash[:success] = t 'flash_messages.instance_admin.settings.locales.created'
      redirect_to redirect_url
    else
      render 'new'
    end
  end

  def edit
  end

  def edit_keys
    @translations = @instance.translations.where(locale: @locale.code)
    @default_and_custom_translations = LocalesService.new(platform_context, q: params[:q])
                                                     .get_locales
                                                     .order('key ASC')
                                                     .paginate(:page => params[:page], :per_page => 50)
  end

  def update
    if @locale.update_attributes(locale_params)
      flash[:success] = t 'flash_messages.instance_admin.settings.locales.updated'
      redirect_to redirect_url
    else
      render 'edit'
    end
  end

  def destroy
    if @locale.destroy
      flash[:success] = t 'flash_messages.instance_admin.settings.locales.deleted'
      redirect_to redirect_url
    else
      flash[:error] = @locale.errors.full_messages.to_sentence
      redirect_to redirect_url
    end
  end

  def new_key
    @translation = @instance.translations.new
  end

  def create_key
    @translation = @instance.translations.new locale: 'en'
    @translation.attributes = translation_params

    if @translation.valid?(:instance_admin)
      @translation.prepend_custom_label
      @translation.save(context: :instance_admin)

      flash[:success] = t 'instance_admin.locales.notices.key_created', key: @translation.key
      redirect_to instance_admin_settings_locales_path
    else
      render 'new_key'
    end
  end

  def destroy_key
    @translation = @instance.translations.find params[:id]
    @translation.destroy

    flash[:success] = t 'instance_admin.locales.notices.key_destroyed'
    redirect_to instance_admin_settings_locales_path
  end

  private

  def redirect_url
    instance_admin_settings_translations_path
  end

  def find_locale
    @locale = platform_context.instance.locales.find(params[:id])
  end

  def locale_params
    params.require(:locale).permit(secured_params.locale)
  end

  def translation_params
    params.require(:translation).permit [:key, :value]
  end
end

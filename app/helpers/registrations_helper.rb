module RegistrationsHelper

  def build_link_for(provider, class_for_links)
    if (authentication = Authentication.find_by_provider_and_user_id(provider.downcase, current_user.id))
      # authentication already exists in the database
      class_for_links += ' connected'
      unless authentication.can_be_deleted?
        class_for_links += ' provider-not-disconnectable'
      end
      link_to authentication_path(authentication), :method => :delete , :class => class_for_links do
        content_tag(:span, t('registrations.social_accounts.disconnect'), :class => "padding ico-#{provider.downcase}")
      end
    else
      # user is not connected to this social provider yet - no authentication in the database
      link_to provider_auth_url(provider.downcase), :class => class_for_links do
        content_tag(:span, t('registrations.social_accounts.connect'), :class => "padding ico-#{provider.downcase}")
      end
    end
  end

end

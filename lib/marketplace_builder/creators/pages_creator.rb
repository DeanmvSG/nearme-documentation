# frozen_string_literal: true
module MarketplaceBuilder
  module Creators
    class PagesCreator < TemplatesCreator
      private

      def object_name
        'Page'
      end

      def cleanup!
        @instance.theme.pages.destroy_all
      end

      def create!(template)
        slug = template.name.parameterize
        page = @instance.theme.pages.where(slug: slug).first_or_initialize
        page.path = template.name
        page.content = template.body if template.body.present?
        page.redirect_url = template.redirect_url if template.redirect_url.present?
        page.redirect_code = template.redirect_code if template.redirect_code.present?
        page.save!
      end

      def success_message(template)
        msg = template.redirect_url.present? ? "#{template.name} (redirect)" : template.name
        MarketplaceBuilder::Logger.log "\t- #{msg}"
      end
    end
  end
end

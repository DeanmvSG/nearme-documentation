# frozen_string_literal: true
module Elastic
  class QueryBuilder
    class UserProfileBuilder
      attr_reader :type

      def self.build(params, profile:)
        new(params, profile: profile).query
      end

      def initialize(params, profile:)
        @params = params
        @profile = profile
        @type = profile.name.downcase
        @query = []
      end

      def query
        add default
        add properties
        add legacy_categories
        add availability_exceptions

        @query
      end

      private

      def add(condition)
        @query.concat Array(condition) if condition.present?
      end

      # TODO: add profile-type categories only when there is related criteria
      def default
        [
          { match: { 'user_profiles.enabled': true } },
          { match: { 'user_profiles.profile_type' => type } }
        ]
      end

      def user_profile_enabled
        @params.dig(:user_profiles, type, :enabled)
      end

      def properties
        @params.dig(:user_profiles, type, :properties)&.flat_map do |key, value|
          next if value.blank?

          Array(value).reject(&:blank?).map do |single|
            { match: { "user_profiles.properties.#{key}" => single } }
          end
        end
      end

      # TODO: review
      def categories
        category_ids = @params[:category_ids].split(',').map(&:to_i)

        if config.category_search_type == 'OR'
          { terms: { 'user_profiles.category_ids': category_ids } }
        else
          category_ids.map do |category|
            { term: { 'user_profiles.category_ids': category } }
          end
        end
      end

      def legacy_categories
        return unless @params[:category_ids]
        return unless type == 'buyer'

        category_ids = @params[:category_ids].split(',').map(&:to_i)

        if config.category_search_type == 'OR'
          { terms: { 'user_profiles.category_ids': category_ids } }
        else
          category_ids.map do |category|
            { term: { 'user_profiles.category_ids': category } }
          end
        end
      end

      def availability_exceptions
        AvailabilityExceptions.new(@params.dig(:user_profiles, type, :availability_exceptions))
      end

      def config
        @profile
      end
    end
  end
end
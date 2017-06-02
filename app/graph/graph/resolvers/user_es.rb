# frozen_string_literal: true
module Graph
  module Resolvers
    class UserEs
      def initialize(query:, ctx:)
        @query = query
        @ctx = ctx
        @graph_field = ctx.field.name
      end

      def fetch
        Elastic::UserCollectionProxy.new(users)
      end

      private

      NESTED_FIELDS_SOURCE_MAPPING = {
        'profile' => 'user_profiles.*',
        'current_address' => 'current_address.*',
        'avatar' => 'avatar.*'
      }.freeze

      MANDATORY_FIELDS = %w(id slug avatar.*).freeze

      def elastic_query
        @query.add source: source_mapper
      end

      def users
        ::User.simple_search(
          elastic_query.to_h,
          instance_profile_types: PlatformContext.current.instance.instance_profile_types.default
        )
      end

      def query_fields
        @query_fields ||= QueryFields.new(@ctx.ast_node).to_h
      end

      def source_mapper
        [
          MANDATORY_FIELDS.dup,
          query_fields[:simple],
          NESTED_FIELDS_SOURCE_MAPPING.slice(*query_fields[:nested].keys).values
        ].flatten.compact
      end
    end
  end
end

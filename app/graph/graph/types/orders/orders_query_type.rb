# frozen_string_literal: true
module Graph
  module Types
    module Orders
      OrdersQueryType = GraphQL::ObjectType.define do
        field :orders do
          type !types[Types::Orders::Order]
          argument :user_id, types.ID
          argument :creator_id, types.ID
          argument :archived, types.Boolean
          argument :state, types[Types::Orders::OrderStateEnum]
          argument :reviewable, types.Boolean
          resolve Resolvers::Orders.new
        end

        field :order do
          type !Types::Orders::Order
          argument :id, !types.ID
          argument :user_id, types.ID
          argument :creator_id, types.ID
          argument :state, types[Types::Orders::OrderStateEnum]
          resolve Resolvers::Order.new
        end
      end
    end
  end
end

# frozen_string_literal: true
require 'test_helper'
require 'graph/schema'

class Graph::SchemaTest < ActiveSupport::TestCase
  setup do
    @context = {}
    @variables = {}
  end

  context 'user query' do
    setup do
      @user = FactoryGirl.create(:user)
      refresh_elastic
    end

    teardown do
      disable_elasticsearch!
    end

    should 'get user' do
      query = %({
        user(slug: "#{@user.slug}") {
          id
          name
          email
          first_name
          last_name
          slug
          seller_average_rating
          profile_path
          avatar_url_thumb
          avatar_url_bigger
          avatar_url_big
          avatar{ url }
          name_with_affiliation
          display_location
          is_followed(follower_id: 123)
          current_address{ address }
          profile(profile_type: "default") {
            profile_type
          }
        }
      })

      assert_equal(
        {
          'id' => @user.id,
          'name' => @user.name,
          'email' => @user.email,
          'first_name' => @user.first_name,
          'last_name' => @user.last_name,
          'slug' => @user.slug,
          'seller_average_rating' => @user.seller_average_rating.to_i,
          'profile_path' => @user.to_liquid.profile_path,
          'avatar_url_thumb' => nil,
          'avatar_url_bigger' => nil,
          'avatar_url_big' => nil,
          'avatar' => nil,
          'name_with_affiliation' => @user.to_liquid.name_with_affiliation,
          'display_location' => @user.to_liquid.display_location,
          'is_followed' => false,
          'current_address' => { 'address' => @user.current_address.address },
          'profile' => { 'profile_type' => 'default' }
        },
        result(query)['user']
      )
    end

    should 'get user custom attribute' do
      add_custom_attribute(attr_name: 'hair_color', value: 'red', object: @user)
      refresh_elastic
      query = %({
        user(id: #{@user.id}) {
          profile(profile_type: "default") {
            hair_color: custom_attribute(name: "hair_color")
          }
        }
      })

      assert_equal(
        @user.properties.hair_color,
        result(query).dig('user', 'profile', 'hair_color')
      )
    end

    should 'get user profile property' do
      add_custom_attribute(attr_name: 'hair_color', value: 'red', object: @user)
      query = %({
        user(id: #{@user.id}) {
          hair_color: profile_property(profile_type: "default", name: "hair_color")
        }
      })

      assert_equal(
        @user.properties.hair_color,
        result(query).dig('user', 'hair_color')
      )
    end


    should 'get user custom photo' do
      query = %({ users { funny_pic: custom_attribute_photos(name: "funny_pic"){ url }}})

      assert_not_nil result(query)
    end

    should 'get user custom model' do
      add_custom_model(model_name: 'Cars', attr_name: 'car_model', object: @user.default_profile)
      refresh_elastic

      query = %({
        user(id: #{@user.id}) {
          profile(profile_type: "default") {
            customizations(name: "Cars") {
              car_model: custom_attribute(name: "car_model")
            }
          }
        }
      })

      assert_equal(
        'mazda',
        result(query).dig('user', 'profile', 'customizations', 0, 'car_model')
      )
    end

    should 'get user pending collaborations' do
      collaboration = FactoryGirl.create(
        :transactable_collaborator,
        user: @user, transactable:
        FactoryGirl.create(:transactable, user: @user)
      )
      User.where.not(id: @user.id).delete_all

      query = %({ users { collaborations(filters: [PENDING_RECEIVED_INVITATION]) { id } }})

      assert_equal({ 'users' => [{ 'collaborations' => [{ 'id' => collaboration.id }] }] }, result(query))
    end

    should 'get user pending group collaborations' do
      group_member = FactoryGirl.create(:group_member_pending, user: @user)
      refresh_elastic

      query = %({
        user(id: #{@user.id}) {
          first_name
          group_collaborations(filters: [PENDING_RECEIVED_INVITATION]) {
            id
            group {
              show_path cover_photo{ url(version: "thumb") }
              creator{ first_name }
            }
          }
        }})

      assert_not_nil result(query)
    end

    should 'user threads' do
      FactoryGirl.create(:user_message, author: @user)
      query = %({ user(id: #{@user.id}) { threads { participant { name } is_read }}})

      assert_equal(
        { 'user' => { 'threads' => [{ 'participant' => { 'name' => @user.name }, 'is_read' => false }] } },
        result(query)
      )
    end

    should 'user thread' do
      message = FactoryGirl.create(:user_message, author: @user, thread_owner: @user, thread_recipient: @user)
      query = %({ user(id: #{@user.id}) { thread(id: #{message.id}) { participant { name } is_read }}})

      assert_equal(
        { 'user' => { 'thread' => { 'participant' => { 'name' => @user.name }, 'is_read' => false } } },
        result(query)
      )
    end

    should 'user thread messages' do
      message = FactoryGirl.create(:user_message, author: @user, thread_owner: @user, thread_recipient: @user)
      FactoryGirl.create(:attachable_attachment, user: @user, attachable: message)
      query = %({ user(id: #{@user.id}) { thread(id: #{message.id}){ messages{attachments{url}}}}})

      assert_not_nil result(query)['user']
    end

    should 'get user reviews' do
      comment = 'very good'
      review = FactoryGirl.create(
        :review,
        comment: comment,
        rating_system: FactoryGirl.create(:rating_system, subject: RatingConstants::HOST)
      )
      review.update_attributes(seller: @user)
      query = %({ user(id: #{@user.id}) {
        id
        reviews{
          comment
          enquirer{ email }
        }
      }})
      refresh_elastic

      data = result(query)

      assert_equal(
        comment,
        data.dig('user', 'reviews', 0, 'comment')
      )
      assert_equal(
        review.buyer.email,
        data.dig('user', 'reviews', 0, 'enquirer', 'email')
      )
    end

    should 'get users with filters' do
      query = %({ users(filters: FEATURED) { id } })

      assert_empty result(query)['users']
    end
  end

  context 'wish_list_items' do
    should 'get items for user' do
      user = FactoryGirl.create(:user)
      wish_list = FactoryGirl.create(:default_wish_list, user: user)
      FactoryGirl.create(:wish_list_item, wish_list: wish_list)
      refresh_elastic

      query = %({ wish_list_items(user_id: #{user.id}) {
        id
        wishlistable{
          ... on User {
            name
          }
        }
      }})

      assert_not_empty result(query)['wish_list_items']

      disable_elasticsearch!
    end
  end

  should 'get activity feed' do
    @user = FactoryGirl.create(:user)
    query = %(
      {
        feed(include_user_feed: true, object_id: #{@user.id}, object_type: "User"){
          owner_id
          owner_type
          has_next_page
          events_next_page
          events{
            id
            name
          }
        }
      })

    assert_not_nil result(query)
  end

  context 'transactable query' do
    should 'get transactable custom photo' do
      query = %({ transactables { funny_pic: custom_attribute_photos(name: "funny_pic"){ url }}})

      assert_not_nil result(query)
    end
  end

  context 'custom attributes xxx' do
    should 'get custom attribute definition' do
      FactoryGirl.create(
        :custom_attribute,
        name: 'foo', target: InstanceProfileType.default.first, attribute_type: 'string'
      )
      query = %({ custom_attribute_definition(name: "foo") { name valid_values }} )

      assert_not_nil result(query)['custom_attribute_definition']
    end
  end


  def result(query)
    Graph.execute_query(
      query,
      context: @context,
      variables: @variables
    )
  end

  def add_custom_attribute(attr_name:, value:, object:)
    FactoryGirl.create(
      :custom_attribute,
      name: attr_name, target: InstanceProfileType.default.first, attribute_type: 'string'
    )
    object.reload.properties.public_send("#{attr_name}=", value)
    object.save!
  end

  def add_custom_model(model_name:, attr_name:, object:)
    default_profile_type = PlatformContext.current.instance.default_profile_type
    model = FactoryGirl.create(:custom_model_type, name: model_name, instance_profile_types: [default_profile_type])
    FactoryGirl.create(:custom_attribute, name: attr_name, target: model)
    object.customizations << Customization.new(custom_model_type: model, properties: { attr_name => 'mazda' })
  end

  def refresh_elastic
    enable_elasticsearch! do
      User.searchable.import
    end
    wait_for_elastic_index
  end
end

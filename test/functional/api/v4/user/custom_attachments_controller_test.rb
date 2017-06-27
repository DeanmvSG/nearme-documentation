# frozen_string_literal: true
require 'test_helper'

module Api
  module V4
    module User
      class CustomAttachmentsControllerTest < ActionController::TestCase
        setup do
          @custom_attachment = FactoryGirl.create(:custom_attachment)
        end

        context 'with authorized user' do
          setup do
            sign_in FactoryGirl.create(:user)
          end

          should 'get file url' do
            get :show, id: @custom_attachment

            assert_redirected_to @custom_attachment.file.url
          end
        end

        context 'without authorized user' do
          should 'not see the attachment' do
            get :show, id: @custom_attachment

            assert_response :unauthorized
          end
        end
      end
    end
  end
end
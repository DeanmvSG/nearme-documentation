require 'test_helper'

class CustomMailerTest < ActiveSupport::TestCase

  module DummyWorkflow
    class DummyStep < WorkflowStep::BaseStep

      def initialize(lister, enquirer, dummy_arg)
        @lister = lister
        @enquirer = enquirer
        @dummy_arg = dummy_arg
      end

      def lister
        @lister
      end

      def enquirer
        @enquirer
      end

      def data
        { dummy_arg: @dummy_arg }
      end

    end
  end

  class DummyArgDrop < BaseDrop
    attr_reader :dummy_arg
    delegate :name, to: :dummy_arg
    def initialize(dummy_arg)
      @dummy_arg = dummy_arg
    end
  end


  setup do
    stub_mixpanel
    @transactable_type = FactoryGirl.create(:transactable_type)
    @step = DummyWorkflow::DummyStep.new(stub(email: 'lister@example.com'), stub(email: 'enquirer@example.com'), stub(to_liquid: DummyArgDrop.new(stub(name: 'dummy name!'))))
    @email_template = FactoryGirl.create(:instance_view_email_text)
    @email_template = FactoryGirl.create(:instance_view_email_html)
    @email_template_for_tt = FactoryGirl.create(:instance_view_email_text, transactable_type_id: @transactable_type.id, body: "Hi TT {{dummy_arg.name}}")
    @email_template_for_tt = FactoryGirl.create(:instance_view_email_html, transactable_type_id: @transactable_type.id, body: "Hi TT {{dummy_arg.name}}")
    @layout_template = FactoryGirl.create(:instance_view_layout)
    @layout_template_for_tt = FactoryGirl.create(:instance_view_layout, transactable_type_id: @transactable_type.id, body: "This is TTHeader {{ content_for_layout }} This is TTFooter")
  end

  should 'be able to send email to lister' do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(from: 'maciek@example.com', reply_to: 'no-reply@example.com', cc: 'cc@example.com', bcc: 'bcc@example.com', recipient: 'my_email@example.com', subject: '[{{platform_context.name}}] This is {{ dummy_arg.name }} subject')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['my_email@example.com'], mail.to
    assert_equal ['maciek@example.com'], mail.from
    assert_equal ['no-reply@example.com'], mail.reply_to
    assert_equal ['cc@example.com'], mail.cc
    assert_equal ['bcc@example.com'], mail.bcc
    assert_equal '[DesksNearMe] This is dummy name! subject', mail.subject
    assert_contains 'Hello dummy name!', mail.html_part.body
    assert_not_contains 'This is header!', mail.html_part.body
    assert_contains 'Hello dummy name!', mail.text_part.body
    assert_not_contains 'This is header!', mail.text_part.body
  end

  should 'work with transactable type id views' do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(layout_path: @layout_template.path)))
    @step.stubs(:transactable_type_id).returns(@transactable_type.id)
    mail = CustomMailer.custom_mail(@step, 1)
    assert_contains 'This is TTHeader Hi TT dummy name! This is TTFooter', mail.html_part.body
    @step.stubs(:transactable_type_id).returns(@transactable_type.id + 1)
    mail = CustomMailer.custom_mail(@step, 1)
    assert_contains 'Hello dummy name!', mail.html_part.body
    assert_contains 'Hello dummy name!', mail.text_part.body
    assert_not_contains 'This is TTHeader', mail.html_part.body
  end

  should "be able to set multiple recipients" do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(recipient: 'mail1@example.com, mail2@example.com')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['mail1@example.com', 'mail2@example.com'], mail.to
  end

  should "be able to set enquirer's email as recipient" do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(recipient_type: 'enquirer')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['enquirer@example.com'], mail.to
  end

  should "be able to set enquirer's email as reply-to" do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(reply_to_type: 'enquirer')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['enquirer@example.com'], mail.reply_to
  end

  should "be able to set enquirer's email as from" do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(from_type: 'enquirer')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['enquirer@example.com'], mail.from
  end

  should "be able to set lister's email as recipient" do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(recipient_type: 'lister')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['lister@example.com'], mail.to
  end

  should "be able to set lister's email as reply-to" do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(reply_to_type: 'lister')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['lister@example.com'], mail.reply_to
  end

  should "be able to set lister's email as from" do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(from_type: 'lister')))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal ['lister@example.com'], mail.from
  end

  should 'be able to use layout' do
    WorkflowAlert.stubs(:find).returns(stub(default_hash.merge(layout_path: @layout_template.path)))
    mail = CustomMailer.custom_mail(@step, 1)
    assert_contains 'This is header Hello dummy name! This is footer', mail.html_part.body
    assert_not_contains 'This is header Hello dummy name! This is footer', mail.text_part.body
  end

  should 'be able to include attachments' do
    WorkflowAlert.stubs(:find).returns(stub(default_hash))
    @step.stubs(:mail_attachments).returns([{name: 'dummy_attachment', value: { content: File.read(Rails.root.join('test', 'assets', 'foobear.jpeg'))} }]).at_least_once
    mail = CustomMailer.custom_mail(@step, 1)
    assert_equal 1, mail.attachments.size
    assert_equal 'dummy_attachment', mail.attachments[0].filename
  end

  should 'use logger instead of db by default for test' do
    WorkflowAlert.stubs(:find).returns(stub(default_hash))
    WorkflowAlertLogger.any_instance.expects(:db_log!).never
    CustomMailer.custom_mail(@step , 1)
  end

  context 'logger' do

    setup do
      WorkflowAlertLogger.setup { |config| config.logger_type = :db }
    end

    should 'create correct log entry for sms' do
      WorkflowAlert.stubs(:find).returns(stub(default_hash))
      WorkflowAlertLogger.any_instance.expects(:db_log!)
      CustomMailer.custom_mail(@step, 1)
    end

    teardown do
      WorkflowAlertLogger.setup { |config| config.logger_type = :none }
    end

  end

  protected

  def default_hash
    { layout_path: nil,
      recipient: 'my_email@example.com',
      recipient_type: nil,
      from: nil,
      from_type: nil,
      reply_to: nil,
      reply_to_type: nil,
      cc: nil,
      bcc: nil,
      template_path: @email_template.path,
      subject: 'Subject'
    }
  end
end


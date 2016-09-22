require 'yaml'
require 'benchmark'
require 'utils/form_components_creator'

namespace :litvault do

  desc 'Setup LitVault'
  task setup: :environment do

    time = Benchmark.realtime do
      @instance = Instance.find(198)
      @instance.update_attributes(
        tt_select_type: 'radio',
        split_registration: true,
        enable_reply_button_on_host_reservations: true,
        hidden_ui_controls: { 'main_menu/cta': 1 },
        skip_company: true
      )
      @instance.set_context!

      InstanceProfileType.find(580).update_columns({
        onboarding: true,
        create_company_on_sign_up: true,
        show_categories: true,
        category_search_type: 'AND',
        searchable: true,
        search_only_enabled_profiles: true
      })

      setup = LitvaultSetup.new(@instance, File.join(Rails.root, 'lib', 'tasks', 'litvault'))
      setup.create_transactable_types!
      setup.create_custom_attributes!
      setup.create_categories!
      setup.create_or_update_form_components!

      setup.set_theme_options

      setup.create_content_holders
      setup.create_liquid_views
      setup.create_mailers
      setup.create_smses
      setup.create_pages
      setup.create_translations

      setup.expire_cache
      setup.create_dashboard_orders_tabs
    end

    puts "\nDone in #{time.round(2)}s\n\n"
  end

  class LitvaultSetup

    def initialize(instance, theme_path)
      @instance = instance
      @theme_path = theme_path
    end

    def create_transactable_types!
      @instance.transactable_types.where.not(name: ['Individual Case', 'Group Case']).destroy_all

      transactable_type = @instance.transactable_types.where(name: 'Individual Case').first_or_initialize
      transactable_type.attributes = {
        name: 'Individual Case',
        slug: 'individual-case',
        action_free_booking: false,
        action_daily_booking: false,
        action_weekly_booking: false,
        action_monthly_booking: false,
        action_regular_booking: true,
        show_path_format: '/:transactable_type_id/:id',
        cancellation_policy_enabled: "1",
        cancellation_policy_hours_for_cancellation: 24,
        cancellation_policy_penalty_hours: 1.5,
        default_search_view: 'list',
        skip_payment_authorization: true,
        hours_for_guest_to_confirm_payment: 24,
        single_transactable: false,
        show_price_slider: true,
        service_fee_guest_percent: 0,
        service_fee_host_percent: 30,
        skip_location: true,
        show_categories: true,
        category_search_type: 'AND',
        bookable_noun: 'Individual Case',
        enable_photo_required: true,
        min_hourly_price_cents: 50_00,
        max_hourly_price_cents: 150_00,
        lessor: 'Lawyer',
        lessee: 'Client',
        enable_reviews: true,
        auto_accept_invitation_as_collaborator: true,
        auto_seek_collaborators: true
      }

      transactable_type.offer_action ||= transactable_type.build_offer_action(
        enabled: true,
        cancellation_policy_enabled: "1",
        cancellation_policy_hours_for_cancellation: 24,
        cancellation_policy_penalty_hours: 1.5,
        service_fee_guest_percent: 0,
        service_fee_host_percent: 30,
      )

      pricing = transactable_type.offer_action.pricings.first_or_initialize
      pricing.attributes = {
        min_price_cents: 50_00,
        max_price_cents: 150_00,
        unit: 'hour',
        number_of_units: 1,
        order_class_name: 'Offer',
        allow_free_booking: false,
        allow_nil_price_cents: true
      }

      merchant_fee = transactable_type.merchant_fees.first_or_initialize
      merchant_fee.attributes = {
        name: "Finder's Fee",
        amount_cents: 10000,
        currency: "USD",
        commission_receiver: "mpo"
      }

      transactable_type.save!
      pricing.save!

      merchant_fee.save!



      transactable_type = @instance.transactable_types.where(name: 'Group Case').first_or_initialize
      transactable_type.attributes = {
        name: 'Group Case',
        slug: 'group-case',
        action_free_booking: false,
        action_daily_booking: false,
        action_weekly_booking: false,
        action_monthly_booking: false,
        action_regular_booking: true,
        show_path_format: '/:transactable_type_id/:id',
        cancellation_policy_enabled: "1",
        cancellation_policy_hours_for_cancellation: 24,
        cancellation_policy_penalty_hours: 1.5,
        default_search_view: 'list',
        skip_payment_authorization: true,
        hours_for_guest_to_confirm_payment: 24,
        single_transactable: false,
        show_price_slider: true,
        service_fee_guest_percent: 0,
        service_fee_host_percent: 30,
        skip_location: true,
        show_categories: true,
        category_search_type: 'AND',
        bookable_noun: 'Group Case',
        enable_photo_required: true,
        min_hourly_price_cents: 50_00,
        max_hourly_price_cents: 150_00,
        lessor: 'Lawyer',
        lessee: 'Client',
        enable_reviews: true,
        auto_accept_invitation_as_collaborator: true
      }

      transactable_type.offer_action ||= transactable_type.build_offer_action(
        enabled: true,
        cancellation_policy_enabled: "1",
        cancellation_policy_hours_for_cancellation: 24,
        cancellation_policy_penalty_hours: 1.5,
        service_fee_guest_percent: 0,
        service_fee_host_percent: 30,
      )

      pricing = transactable_type.offer_action.pricings.first_or_initialize
      pricing.attributes = {
        min_price_cents: 50_00,
        max_price_cents: 150_00,
        unit: 'hour',
        number_of_units: 1,
        order_class_name: 'Offer',
        allow_free_booking: false,
        allow_nil_price_cents: true
      }

      merchant_fee = transactable_type.merchant_fees.first_or_initialize
      merchant_fee.attributes = {
        name: "Finder's Fee",
        amount_cents: 10000,
        currency: "USD",
        commission_receiver: "mpo"
      }

      transactable_type.save!
      pricing.save!

      merchant_fee.save!
    end

    def create_custom_attributes!
      create_transactable_type_attributes
      create_instance_profile_type_attributes
    end

    def create_transactable_type_attributes
      puts "\nCustom transactable type attributes:"

      custom_attributes = YAML.load_file(File.join(@theme_path, 'custom_attributes', 'transactable_types.yml'))

      custom_attributes.keys.each do |tt_name|
        puts "\n\t#{tt_name}:"
        object = @instance.transactable_types.where(name: tt_name).first
        update_custom_attributes_for_object(object, custom_attributes[tt_name])
      end
    end

    def create_instance_profile_type_attributes
      puts "\nCustom instance profile type attributes:"
      custom_attributes = YAML.load_file(File.join(@theme_path, 'custom_attributes', 'instance_profile_types.yml'))

      custom_attributes.keys.each do |id|
        puts "\n\tInstanceProfileType ##{id}:"
        object = InstanceProfileType.find(id)
        update_custom_attributes_for_object(object, custom_attributes[id])
      end
    end

    def create_categories!
      puts "\nCreating categories:"
      categories = YAML.load_file(File.join(@theme_path, 'categories', 'transactable_types.yml'))

      remove_unused_categories(categories)

      categories.keys.each do |tt_name|
        puts "\n\t#{tt_name}:"
        object = @instance.transactable_types.where(name: tt_name).first
        update_categories_for_object(object, categories[tt_name])
      end
    end

    def create_or_update_form_components!
      puts "\nCreating form components:"
      transactable_types = YAML.load_file(File.join(@theme_path, 'form_components', 'transactable_types.yml'))

      transactable_types.keys.each do |tt_name|
        puts "\n\t#{tt_name}:"
        object = @instance.transactable_types.where(name: tt_name).first

        puts "\t  Cleanup..."
        object.form_components.destroy_all
        create_form_components_for_object(object, transactable_types[tt_name])
      end


      FormComponent.find(5404).update_attribute(:form_fields, [ { "user" => "name" }, { "user" => "email" }, { "user" => "password" }, { "buyer" => "law_firm" } ])
      FormComponent.find(5402).update_attribute(:form_fields, [ { "user" => "name" }, { "user" => "email" }, { "user" => "password" }, { "buyer" => "law_firm" } ])
    end

    def set_theme_options
      @theme = @instance.theme
      @theme.color_green = '#4fc6e1'
      @theme.color_blue = '#4fc6e1'
      @theme.call_to_action = 'Learn more'
      @theme.phone_number = '1-555-555-55555'
      @theme.contact_email = 'support@litvault.com'
      @theme.support_email = 'support@litvault.com'
      @theme.facebook_url = 'https://facebook.com'
      @theme.twitter_url = 'https://twitter.com'
      @theme.gplus_url = 'https://plus.google.com'
      @theme.instagram_url = 'https://www.instagram.com'
      @theme.youtube_url = 'https://www.youtube.com'
      @theme.blog_url = 'http://blog.com'
      @theme.linkedin_url = 'https://www.linkedin.com'
      @theme.updated_at = Time.now

      @theme.remote_favicon_image_url = 'https://d2rw3as29v290b.cloudfront.net/instances/198/uploads/ckeditor/picture/data/2816/favicon.png'
      @theme.remote_icon_retina_image_url = 'https://d2rw3as29v290b.cloudfront.net/instances/198/uploads/ckeditor/picture/data/2815/apple-touch-icon.png'

      @theme.save!
    end

    def create_custom_validators!
      cv = CustomValidator.where(field_name: 'mobile_number', validatable: InstanceProfileType.seller.first).first_or_initialize
      cv.required = "1"
      cv.save!

      cv = CustomValidator.where(field_name: 'mobile_number', validatable: InstanceProfileType.buyer.first).first_or_initialize
      cv.required = "1"
      cv.save!
    end

    def create_pages
      puts "\nCreating pages:"

      @instance.theme.pages.destroy_all

      templates = get_templates_from_dir(File.join(@theme_path, 'pages'))
      templates.each do |template|
        create_page(template.name, template.body)
        puts "\t- #{template.name}"
      end
    end

    def create_content_holders
      puts "\nCreating content holders:"

      @instance.theme.content_holders.destroy_all

      templates = get_templates_from_dir(File.join(@theme_path, 'content_holders'), {
        inject_pages: 'any_page',
        position: 'head_bottom'
      })

      templates.each do |template|
        create_content_holder(template.name, template.body, template.inject_pages, template.position)
        puts "\t- #{template.name}"
      end
    end

    def create_mailers
      puts "\nCreating mailers:"
      templates = get_templates_from_dir(File.join(@theme_path, 'mailers'))
      templates.each do |template|
        create_email(template.liquid_path, template.body)
        puts "\t- #{template.name}"
      end
    end

    def create_smses
      puts "\nCreating smses:"
      templates = get_templates_from_dir(File.join(@theme_path, 'sms'))
      templates.each do |template|
        create_email(template.liquid_path, template.body)
        puts "\t- #{template.name}"
      end
    end

    def create_liquid_views
      puts "\nCreating liquid views:"

      templates = get_templates_from_dir(File.join(@theme_path, 'liquid_views'), {
        partial: true
      })

      templates.each do |template|
        create_liquid_view(template.liquid_path, template.body, template.partial)
        puts "\t- #{template.name}"
      end
    end

    # TODO: This should support multiple locales
    def create_translations
      puts "\nTranslating:"

      transformation_hash = {
        'reservation' => 'offer',
        'Reservation' => 'Offer',
        'booking' => 'offer',
        'Booking' => 'Offer',
        'host' => 'Referring Lawyer',
        'Host' => 'Referring Lawyer',
        'guest' => 'Handling Lawyer',
        'Guest' => 'Handling Lawyer',
        'this listing' => 'your Case',
        'that listing' => 'your Case',
        'This listing' => 'Your Case',
        'That listing' => 'Your Case',
        'listing' => 'Case'
      }

      (Dir.glob(Rails.root.join('config', 'locales', '*.en.yml')) + Dir.glob(Rails.root.join('config', 'locales', 'en.yml'))).each do |yml_filename|
        en_locales = YAML.load_file(yml_filename)
        en_locales_hash = convert_hash_to_dot_notation(en_locales['en'])

        en_locales_hash.each_pair do |key, value|
          next if value.blank?
          new_value = value
          transformation_hash.keys.each do |word|
            new_value = new_value.gsub(word, transformation_hash[word])
          end

          new_value.gsub!('Cases_count', 'listings_count')

          if value != new_value
            t = Translation.find_or_initialize_by(locale: 'en', key: key, instance_id: @instance.id)
            t.value = new_value
            t.skip_expire_cache = true
            t.save!
            print '.'
            $stdout.flush
          end
        end
      end

      locales = YAML.load_file(File.join(@theme_path, 'translations', 'en.yml'))
      locales_hash = convert_hash_to_dot_notation(locales['en'])

      locales_hash.each_pair do |key, value|
        create_translation(key, value, 'en')
        print '.'
        $stdout.flush
      end

      puts "\n"
    end


    def expire_cache
      puts "\nClearing cache..."
      CacheExpiration.send_expire_command 'InstanceView', instance_id: @instance.id
      CacheExpiration.send_expire_command 'Translation', instance_id: @instance.id
      CacheExpiration.send_expire_command 'CustomAttribute', instance_id: @instance.id
      Rails.cache.clear
    end

    def create_dashboard_orders_tabs
      @instance.my_orders_tabs = %w(unconfirmed confirmed archived draft)
      @instance.save
    end

    private

      def convert_hash_to_dot_notation(hash, path = '')
        hash.each_with_object({}) do |(k, v), ret|
          key = path + k

          if v.is_a? Hash
            ret.merge! convert_hash_to_dot_notation(v, key + ".")
          else
            ret[key] = v
          end
        end
      end

      def get_templates_from_dir(template_folder, defaults = {})
        template_files = Dir.entries(template_folder).select{ |e| File.file?(File.join(template_folder, e)) && e != '.keep' }
        template_files.map! { |filename| load_file_with_yaml_front_matter(File.join(template_folder, filename), defaults) }
      end

      def create_email(path, body)
        iv = InstanceView.where(instance_id: @instance.id, view_type: 'email', path: path, handler: 'liquid', format: 'html', partial: false).first_or_initialize
        iv.locales = Locale.all
        iv.transactable_types = TransactableType.all
        iv.body = body
        iv.save!

        iv = InstanceView.where(instance_id: @instance.id, view_type: 'email', path: path, handler: 'liquid', format: 'text', partial: false).first_or_initialize
        iv.body = ActionView::Base.full_sanitizer.sanitize(body)
        iv.locales = Locale.all
        iv.transactable_types = TransactableType.all
        iv.save!
      end

      def create_sms(path, body)
        iv = InstanceView.where(instance_id: @instance.id, view_type: 'sms', path: path, handler: 'liquid', format: 'text', partial: false).first_or_initialize
        iv.locales = Locale.all
        iv.transactable_types = TransactableType.all
        iv.body = body
        iv.save!
      end

      def create_page(path, body)
        slug = path.parameterize
        page = @instance.theme.pages.where(slug: slug).first_or_initialize
        page.path = path
        page.content = body
        page.save
      end

      def create_content_holder(name, body, inject_pages, position)
        inject_pages = [inject_pages] if inject_pages.kind_of?(String)
        ch = @instance.theme.content_holders.where(
          name: name
        ).first_or_initialize

        ch.update!({
          content: body,
          inject_pages: inject_pages,
          position: position
        })
      end

      def create_translation(key, value, locale)
        @instance.translations.where(
          locale: locale,
          key: key
        ).first_or_initialize.update!(value: value)
      end

      def create_liquid_view(path, body, partial)
        iv = InstanceView.where(
          instance_id: @instance.id,
          path: path,
        ).first_or_initialize
        iv.update!({
          transactable_types: TransactableType.all,
          body: body,
          format: 'html',
          handler: 'liquid',
          partial: partial,
          view_type: 'view',
          locales: Locale.all
        })
      end

      def load_file_with_yaml_front_matter(path, config = {})
        body = File.read(path)
        regex = /\A---(.|\n)*?---\n/

        # search for YAML front matter
        yfm = body.match(regex)
        if yfm
          config = config.merge(YAML.load(yfm[0]))
          body.gsub!(regex, '')
        end
        config = config.merge({ body: body })

        config["liquid_path"] ||= File.basename(path, '.*').gsub('--','/')
        config["name"] ||= File.basename(path, '.*').gsub('--','/').humanize.titleize
        config["path"] ||= path

        OpenStruct.new(config)
      end

      def create_custom_attribute(object, name, hash)
          hash = hash.with_indifferent_access
          attr = object.custom_attributes.where({
            name: name
          }).first_or_initialize
          attr.assign_attributes(hash)
          attr.set_validation_rules!
      end

      def remove_unused_categories(categories)
        used_categories = []
        categories.each do |tt, cats|
          used_categories.concat(cats.keys)
        end
        used_categories.uniq!

        unused_categories = Category.where("name NOT IN (?) AND parent_id IS NULL", used_categories)
        if unused_categories.size > 0
          puts "\tRemoving unused categories:"
          unused_categories.each do |category|
            puts "\t  - #{category.name}"
            category.destroy!
          end
        end
      end

      def update_categories_for_object(tt, categories)
        puts "\t  Updating / creating categories:"
        categories.each do |name, hash|
          hash = default_category_properties.merge(hash)
          children = hash.delete('children') || []

          category = Category.where(name: name).first_or_create!
          category.transactable_types = category.transactable_types.push(tt) if !category.transactable_types.include?(tt)
          category.assign_attributes(hash)
          category.save!

          puts "\t    - #{name}"

          create_category_tree(category, children, 1)
        end
      end

      def create_category_tree(category, children, level)
        children.each do |child|
          name = (child.is_a? Hash) ? child['name'] : child
          subcategory = category.children.where(name: name).first_or_create!
          puts "\t    #{'  ' * (level + 1)}- #{name}"
          # create_category_tree(subcategory, child['children'], level + 1) if child['children']
        end
      end

      def update_custom_attributes_for_object(object, attributes)
        unused_attrs = object.custom_attributes.where("name NOT IN (?)", attributes.keys)
        if unused_attrs.size > 0
          puts "\t  Removing unused attributes:"
          unused_attrs.each do |ca|
            puts "\t    - #{ca.name}"
            ca.destroy
          end
        end

        puts "\t  Updating / creating attributes:"
        attributes.each do |name, attrs|
          create_custom_attribute(object, name, default_attribute_properties.merge(attrs))
          puts "\t    - #{name}"
        end
      end

      def default_category_properties
        {
          mandatory: false,
          multiple_root_categories: false,
          search_options: 'exclude',
          children: []
        }
      end

      def default_attribute_properties
        {
          attribute_type: 'string',
          html_tag: 'input',
          public: true,
          searchable: false,
          required: false
        }
      end

      def create_form_components_for_object(object, component_types)
        component_types.each do |type, components|
          puts "\t  Creating #{type}..."
          creator = Utils::BaseComponentCreator.new(object)
          creator.instance_variable_set(:@form_type_class, "FormComponent::#{type}".safe_constantize)
          components.map!{|component| component.symbolize_keys }
          creator.create_components!(components)
        end
      end

  end
end

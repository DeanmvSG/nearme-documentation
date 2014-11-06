module CustomAttributes
  class CustomAttribute::Creator

    def initialize(target, bookable_noun = 'Desk')
      @target = target
      @bookable_noun = bookable_noun
    end

    def create_listing_attributes!
      {
        name: :string,
        description: :string,
        listing_type: :string,
        quantity: :integer,
        capacity: :integer,
        delta: :boolean,
        minimum_booking_minutes: :integer,
        rank: :integer,
        last_request_photos_sent_at: :datetime,
      }.each do |attr_name, attr_type|
        tta = @target.custom_attributes.where(name: attr_name).first || CustomAttribute.new(target: @target)

        default = case attr_name
                  when :quantity
                    1
                  when :delta, :listings_public
                    true
                  when :rank
                    0
                  else
                    nil
                  end
        public_flag =  case  attr_name
                       when :listing_type, :quantity, :capacity, :name, :description
                         true
                       else
                         false
                       end

        internal_flag =  case  attr_name
                         when :quantity, :name, :description, :minimum_booking_minutes, :last_request_photos_sent_at
                           true
                         else
                           false
                         end

        validation_rules = case attr_name
                           when :quantity
                             { :presence => {}, :numericality => { greater_than: 0, only_integer: true } }
                           when :description
                             { :length => { :maximum => 250 }, :presence => {} }
                           when :name
                             { :length => { :maximum => 50 }, :presence => {} }
                           when :listing_type
                             { :presence => {} }
                           else
                             {}
                           end
        rest_attributes = case attr_name
                          when :quantity
                            {
                              label:  'Quantity available',
                              input_html_options: { :class => "mini" },
                              hint: "How many of this type of #{@bookable_noun} do you have available?",
                              placeholder: 2

                            }
                          when :capacity
                            {
                              hint: "How many people does your #{@bookable_noun} accommodate?",
                              placeholder: 1,
                              input_html_options: { :class => "mini" }
                            }

                          when :listing_type
                            {
                              html_tag: "select",
                              prompt: "",
                              valid_values: ["Desk", "Meeting Room", "Office Space", "Salon Booth"],
                              input_html_options: { :class => 'selectpicker' },
                              label: "#{@bookable_noun} type"
                            }
                          when :name
                            {
                              label: "#{@bookable_noun} name"
                            }
                          when :description
                            {
                              label: "#{@bookable_noun} description"
                            }
                          else
                            {}
                          end
        tta.attributes = {
          name: attr_name,
          attribute_type: attr_type.to_s,
          html_tag: 'input',
          public: public_flag,
          internal: internal_flag,
          default_value: default,
          validation_rules: validation_rules,
          valid_values: [],
          input_html_options: {}
        }.merge(rest_attributes)
        tta.save!
      end
    end

    def create_buy_sell_attributes!
    end

  end

end

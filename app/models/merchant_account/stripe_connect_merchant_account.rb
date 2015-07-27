class MerchantAccount::StripeConnectMerchantAccount < MerchantAccount

  ATTRIBUTES = %w(currency bank_routing_number bank_account_number tos account_type business_tax_id business_vat_id ssn_last_4 personal_id_number)
  ACCOUNT_TYPES = %w(individual company)

  SUPPORTED_CURRENCIES = {
    'US'   => %w(USD),
    'CA'   => %w(USD CA),
    'AU'   => %w(AUD),
    'JP'   => %w(JPY),
    'EUUK' => %w(EUR GBP USD),
  }

  include MerchantAccount::Concerns::DataAttributes

  has_many :owners, -> { order(:id) }, class_name: 'MerchantAccountOwner::StripeConnectMerchantAccountOwner', foreign_key: 'merchant_account_id', dependent: :destroy

  validates_presence_of   :bank_routing_number, message: 'Bank routing number is blank'
  validates_presence_of   :bank_account_number, message: 'Bank account number is blank'
  validates_inclusion_of  :account_type, in: ACCOUNT_TYPES, message: 'Account type should be selected'
  validates_acceptance_of :tos, message: 'Terms of Services must be accepted'

  accepts_nested_attributes_for :owners, allow_destroy: true

  def onboard!
    result = payment_gateway.onboard!(create_params)
    handle_result(result)
  end

  def update_onboard!
    result = payment_gateway.update_onboard!(internal_payment_gateway_account_id, update_params)
    handle_result(result)
  end

  def handle_result(result)
    if result.id
      self.internal_payment_gateway_account_id = result.id
      self.data[:fields_needed] = result.verification.fields_needed
      upload_documents(result)
      self.response = result.to_yaml
      self.bank_account_number = result.bank_accounts.first.last4
      self.data[:currency] = result.default_currency
      if result.keys.is_a?(Stripe::StripeObject)
        self.data[:secret_key] = result.keys.secret
      end
      change_state_if_needed(result)
      true
    elsif result.error
      errors.add(:data, result.error)
      false
    else
      false
    end
  end

  def create_params
    update_params.deep_merge(
      managed: true,
      country: merchantable.iso_country_code,
      email: merchantable.creator.email,
      tos_acceptance: {
        ip: merchantable.creator.current_sign_in_ip,
        date: Time.now.to_i
      },
      legal_entity: {
        first_name: merchantable.creator.first_name,
        last_name: merchantable.creator.last_name
      },
      decline_charge_on: {
        cvc_failure: true
      }
    )
  end

  def update_params
    owner = owners.first
    dob_components = owner.dob.split('-')

    address_hash = {
      country: merchantable.iso_country_code,
      state: merchantable.state,
      city: merchantable.city,
      postal_code: merchantable.postcode,
      # Address line 1 (Street address/PO Box/Company name).
      line1: merchantable.address,
      # Address line 2 (Apartment/Suite/Unit/Building).
      line2: merchantable.address2
    }

    legal_entity_hash = {
      type: account_type,
      business_name: merchantable.name,
      address: address_hash,
      personal_address: address_hash,
      dob: {
        day:   dob_components[2],
        month: dob_components[1],
        year:  dob_components[0]
      },
      ssn_last_4:         ssn_last_4,
      business_tax_id:    business_tax_id,
      business_vat_id:    business_vat_id,
      personal_id_number: personal_id_number
    }

    if owners.count == 1
      legal_entity_hash.merge!(additional_owners: nil)
    else
      legal_entity_hash.merge!(additional_owners: [])
      owners[1..-1].each do |owner|

        dob_components = owner.dob.split('-')
        legal_entity_hash[:additional_owners] << {
          first_name: owner.first_name,
          last_name:  owner.last_name,
          address: {
            country:     owner.address_country,
            state:       owner.address_state,
            city:        owner.address_city,
            postal_code: owner.address_postal_code,
            line1:       owner.address_line1,
            line2:       owner.address_line2,
          },
          dob: {
            day:   dob_components[2],
            month: dob_components[1],
            year:  dob_components[0]
          }
        }
      end
    end

    {
      bank_account: {
        country: merchantable.iso_country_code,
        currency: get_currency,
        account_number: bank_account_number,
        routing_number: bank_routing_number
      }
    }.merge(legal_entity: legal_entity_hash)
  end

  def change_state_if_needed(stripe_account)
    if !verified? && stripe_account.charges_enabled && stripe_account.transfers_enabled && stripe_account.verification.fields_needed.empty?
      verify(persisted?)
    elsif verified? && (!stripe_account.charges_enabled || !stripe_account.transfers_enabled || !stripe_account.verification.fields_needed.empty?)
      to_pending(persisted?)
    end
  end

  def get_currency
    case merchantable.iso_country_code
    when 'US'
      'USD'
    when 'AU'
      'AUD'
    when 'JP'
      'JPY'
    else
      currency
    end
  end

  def location
    country = merchantable.iso_country_code.downcase
    country.in?(%w(us ca au jp)) ? country : 'euuk'
  end

  def needs?(attribute)
    self.data[:fields_needed].try(:include?, attribute)
  end

  private

  def upload_documents(stripe_account)
    files_data = owners.map { |owner| owner.upload_document(stripe_account.id) }
    if files_data.compact!.present?
      stripe_account.legal_entity.verification.document = files_data[0].id
      if stripe_account.legal_entity.additional_owners
        files_data[1..-1].each_with_index do |file_data, index|
          if stripe_account.legal_entity.additional_owners[index]
            stripe_account.legal_entity.additional_owners[index].verification.document = file_data.id
          end
        end
      end
      stripe_account.save
    end
  end

end
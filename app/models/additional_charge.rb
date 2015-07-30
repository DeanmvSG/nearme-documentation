class AdditionalCharge < ActiveRecord::Base
  has_paper_trail
  auto_set_platform_context
  scoped_to_platform_context

  after_initialize :copy_ac_type_data, if: :new_record?

  belongs_to :instance
  belongs_to :additional_charge_type
  belongs_to :target, polymorphic: true

  validates :additional_charge_type_id, presence: true

  monetize :amount_cents, with_model_currency: :currency

  scope :mandatory, -> { where(status: 'mandatory') }

  def mandatory?
    status == 'mandatory'
  end

  def optional?
    status == 'optional'
  end

  private
  # We need to copy this data from AdditionalChargeType record
  # to have accurate information about the charge
  # since information in AdditionalChargeType can change with time
  def copy_ac_type_data
    return if additional_charge_type_id.blank?
    self.name = additional_charge_type.name

    #amount in additional_charge_type is in USD. If we try to copy amount_cents, it already includes conversion to cents in 100 to 1 ratio.
    # If additional charge is in different currency, we need to make sure that we make proper conversion from 100 to 1 ratio into currency's ratio.
    # MGA for example uses 5 to 1 ratio, so if amount to copy is 25, we transform it into 2500. We then divide this by 100 / 5 -> 2500 / 20 -> 125.
    # It is then correct amount, because 125 / 5 gives us again initial 25 full 'dollar' amount. Test coverage in test/integrations/commissions<tab>
    self.amount_cents = additional_charge_type.amount_cents / (100 / Money::Currency.new(currency.presence || PlatformContext.current.instance.default_currency).subunit_to_unit.to_f)
    self.commission_receiver = additional_charge_type.commission_receiver
    self.status = additional_charge_type.status
  end
end

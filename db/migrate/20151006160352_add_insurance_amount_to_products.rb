class AddInsuranceAmountToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :insurance_amount, :decimal, precision: 10, scale: 2, default: 0.0, null: false
  end
end
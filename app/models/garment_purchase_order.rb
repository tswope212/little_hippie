class GarmentPurchaseOrder < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :billing_address
  belongs_to :shipping_address
  attr_accessible :supplier_id, :billing_address_id, :shipping_address_id
end

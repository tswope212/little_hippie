class Delivery < ActiveRecord::Base
  belongs_to :delivery_address
  belongs_to :quantity
  has_one :garment, :through => :quantity
  has_many :received_inventories
  attr_accessible :delivery_address_id, :quantity_id, :quantity_delivered
  
  def name
    "#{quantity_delivered}/#{quantity.name} to #{delivery_address.name}"
  end
end

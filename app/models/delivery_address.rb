class DeliveryAddress < ActiveRecord::Base
  belongs_to :state
  belongs_to :country
  attr_accessible :city, :email, :first_name, :hidden, :last_name, :phone, :position, :street, :street2, :zip
end

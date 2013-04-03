class Charge < ActiveRecord::Base
  belongs_to :cart
  attr_accessible :cart_id, :amount, :token
  scope :complete, where(:result => 'complete')
  
  def dollar_amount
    amount / 100.0
  end
end

class Cart < ActiveRecord::Base
  belongs_to :customer
  belongs_to :shipping_address # the shipping address assigned to the cart
  has_many :shipping_addresses # any shipping addresses created during checkout for this cart
  has_many :items, :dependent => :destroy
  has_many :charges, :dependent => :destroy
  belongs_to :coupon
  attr_accessible :status, :customer, :ip_address, :gift_note, :tracking_number, :referral_type, :shipping_method
  scope :complete, where({:status => [1, 2]})
  scope :unpurchased, where({:status => nil})
  
  STANDARD_SHIPPING = 1
  RUSH_SHIPPING = 2
  EXPEDITED_SHIPPING = 3
  
  before_update :update_shipment_status
  
  def status_word
    case status
    when 1
      'paid'
    when 2
      'shipped'
    else
      'not purchased'
    end
  end
  
  def unpurchased?
    status.nil?
  end
  
  def update_shipment_status
    if tracking_number.present?
      self.status = 2
    end
  end
  
  def subtotal
    items.inject(0) { |sum, item| sum + item.cost }
  end
  
  def total
    subtotal_after_coupon + shipping_charge
  end
  
  def subtotal_after_coupon
    if coupon.andand.percentage.present?
      coupon_rate = (100 - coupon.percentage) / 100.0
      if coupon.upper_limit.present?
        return total if total * 100 > coupon.upper_limit
      end
      items.inject(0) do |sum, item|
        if coupon.valid_for? item.product
          item_cost = item.cost * coupon_rate
        else
          item_cost = item.cost
        end
        sum + item_cost
      end
    elsif coupon.andand.amount.present?
      if coupon.lower_limit.present?
        return total if total * 100 < coupon.lower_limit
      end
      if items.map(&:product).any? { |product| coupon.valid_for? product }
        subtotal - (coupon.amount / 100.0)
      else
        subtotal
      end
    else
      subtotal
    end
  end
  
  def discount_amount
    self.coupon ||= charges.last.andand.coupon
    total - subtotal_after_coupon
  end
  
  def shipping_charge
    self.shipping_method ||= STANDARD_SHIPPING
    case subtotal * 100
    when (0..999)
      case shipping_method
      when STANDARD_SHIPPING
        595
      when RUSH_SHIPPING
        1395
      when EXPEDITED_SHIPPING
        2595
      end
    when (1000..1999)
      case shipping_method
      when STANDARD_SHIPPING
        695
      when RUSH_SHIPPING
        1495
      when EXPEDITED_SHIPPING
        2695
      end
    when (2000..2999)
      case shipping_method
      when STANDARD_SHIPPING
        795
      when RUSH_SHIPPING
        1595
      when EXPEDITED_SHIPPING
        2795
      end
    when (3000..3999)
      case shipping_method
      when STANDARD_SHIPPING
        995
      when RUSH_SHIPPING
        1795
      when EXPEDITED_SHIPPING
        2995
      end
    when (4000..4999)
      case shipping_method
      when STANDARD_SHIPPING
        1095
      when RUSH_SHIPPING
        1895
      when EXPEDITED_SHIPPING
        3095
      end
    when (5000..5999)
      case shipping_method
      when STANDARD_SHIPPING
        1195
      when RUSH_SHIPPING
        1995
      when EXPEDITED_SHIPPING
        3195
      end
    when (6000..7999)
      case shipping_method
      when STANDARD_SHIPPING
        1295
      when RUSH_SHIPPING
        2095
      when EXPEDITED_SHIPPING
        3295
      end
    when (8000..9999)
      case shipping_method
      when STANDARD_SHIPPING
        1495
      when RUSH_SHIPPING
        2295
      when EXPEDITED_SHIPPING
        3495
      end
    when (10000..14999)
      case shipping_method
      when STANDARD_SHIPPING
        1695
      when RUSH_SHIPPING
        2495
      when EXPEDITED_SHIPPING
        3695
      end
    when (15000..19999)
      case shipping_method
      when STANDARD_SHIPPING
        2595
      when RUSH_SHIPPING
        3395
      when EXPEDITED_SHIPPING
        4595
      end
    when (20000..24999)
      case shipping_method
      when STANDARD_SHIPPING
        3095
      when RUSH_SHIPPING
        3895
      when EXPEDITED_SHIPPING
        5095
      end
    when (25000..29999)
      case shipping_method
      when STANDARD_SHIPPING
        3595
      when RUSH_SHIPPING
        4395
      when EXPEDITED_SHIPPING
        5595
      end
    when (30000..34999)
      case shipping_method
      when STANDARD_SHIPPING
        4095
      when RUSH_SHIPPING
        4895
      when EXPEDITED_SHIPPING
        6095
      end
    when (35000..39999)
      case shipping_method
      when STANDARD_SHIPPING
        4595
      when RUSH_SHIPPING
        5395
      when EXPEDITED_SHIPPING
        6595
      end
    when (40000..449990000000)
      case shipping_method
      when STANDARD_SHIPPING
        5095
      when RUSH_SHIPPING
        5895
      when EXPEDITED_SHIPPING
        7095
      end
    end / 100.0
  end
  
  def item_quantity
    items.sum :quantity
  end
  
  def apparent_primary_shipping_address
    if shipping_address.present?
      shipping_address
    else
      shipping_addresses.last
    end
  end
  
  def update_inventory
    items.each do |item|
      garment = item.garment
      garment.andand.inventory.andand.update_attribute :current_amount, garment.andand.inventory.andand.current_amount.andand.-(item.quantity)
    end
  end
end

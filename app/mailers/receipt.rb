class Receipt < ActionMailer::Base
  include Resque::Mailer
  default from: "little.hippie.messenger@gmail.com"#, bcc: 'receipts@littlehippie.com'
  
  def purchase_receipt charge_id, stripe_customer
    @charge = Charge.find charge_id
    @cart = @charge.cart
    @coupon = @cart.coupon
    @items = @cart.items
    @customer = @cart.customer
    @shipping_address = @cart.apparent_primary_shipping_address
    @stripe_customer = stripe_customer
    @billing_address = stripe_customer['active_card']['name']
    @billing_address += "<br>#{stripe_customer['active_card']['address_line1']}"
    @billing_address += "<br>#{stripe_customer['active_card']['address_line2']}" if stripe_customer['active_card']['address_line2'].present?
    @billing_address += "<br>#{stripe_customer['active_card']['address_city']} #{stripe_customer['active_card']['address_zip']}"
    @billing_address += "<br>#{stripe_customer['active_card']['address_state']}, #{stripe_customer['active_card']['address_country']}"
    @billing_address += "<br>**** **** **** #{stripe_customer['active_card']['last4']}"
    subject = "Your Little Hippie order"
    to = [@customer.andand.email, stripe_customer['email']].compact.uniq
    mail :to => to, :subject => subject
  end
  
  def shipment_tracking cart_id
    @cart = Cart.find cart_id
    @customer = @cart.customer
    @shipping_address = @cart.apparent_primary_shipping_address
    @shipping_provider = @cart.shipping_method == Cart::STANDARD_SHIPPING ? 'USPS' : 'UPS'
    mail :to => [@shipping_address.email, @customer.andand.email].compact.uniq, :subject => 'Tracking # for your Little Hippie Order'
  end
  
  def detect_email text
    text.split(' ').select { |t| t =~ /\@/ }.first
  end
end

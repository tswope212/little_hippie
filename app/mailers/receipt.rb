class Receipt < ActionMailer::Base
  default from: "orders@littlehippie.com", bcc: 'receipts@littlehippie.com'
  
  def purchase_receipt charge, stripe_customer
    cart = charge.cart
    @items = cart.items
    @customer = cart.customer
    @shipping_address = cart.apparent_primary_shipping_address
    @billing_address = stripe_customer.active_card.name
    @billing_address += "<br>#{stripe_customer.active_card.address_line1}"
    @billing_address += "<br>#{stripe_customer.active_card.address_line2}" if stripe_customer.active_card.address_line2.present?
    @billing_address += "<br>#{stripe_customer.active_card.address_city} #{stripe_customer.active_card.address_zip}"
    @billing_address += "<br>**** **** **** #{stripe_customer.active_card.last4}"
    @billing_address.html_safe
    subject = "Your Little Hippie order"
    to = [@customer.andand.email, detect_email(stripe_customer.description)].compact
    mail :to => to, :subject => subject
  end
  
  def detect_email text
    text.split(' ').select { |t| t =~ /\@/ }.first
  end
end
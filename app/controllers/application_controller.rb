class ApplicationController < ActionController::Base
  protect_from_forgery
  
  helper_method :current_cart
  
  def current_cart(give_to_customer = nil)
    if session[:cart_id].present?
      begin
        @cart = Cart.find session[:cart_id]
      rescue ActiveRecord::RecordNotFound
        Rails.logger.info "cart not found"
      end
      if give_to_customer
        @cart.update_attribute :customer_id, current_customer.id
      elsif current_customer.present?
        unless @cart.customer_id == current_customer.id
          @cart = Cart.create :customer => current_customer
          session[:cart_id] = @cart.id
        end
      end
    else
      @cart = Cart.create :customer => current_customer
      session[:cart_id] = @cart.id
    end
    @cart
  end
  
end

class FulfillmentController < ApplicationController
  
  def new_orders
    orders = Charge.ready_for_old_glory.map(&:id)
    respond_to do |format|
      format.json { render :json => orders }
    end
  end
  
  def fulfillment_details
    @charge = Charge.find params[:id]
    @cart = @charge.cart
    @shipping_address = @cart.apparent_primary_shipping_address
    @charge.update_attribute :result, 'Old Glory notified'
  end
  
  def tracking_number
    @charge = Charge.find params[:id]
    @cart = @charge.cart
    @cart.update_attribute :tracking_number, params[:tracking_number]
    Receipt.shipment_tracking(@cart.id).deliver
    render :nothing => true
  end
end
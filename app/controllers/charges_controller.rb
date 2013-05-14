class ChargesController < ApplicationController
  before_filter :authenticate_product_manager!, :only => [:index, :edit, :update, :destroy]
  # GET /charges
  # GET /charges.json
  def index
    @charges = Charge.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @charges }
    end
  end

  # GET /charges/1
  # GET /charges/1.json
  def show
    @charge = Charge.find(params[:id])

    respond_to do |format|
      format.html { render :layout => 'customer' }
      format.json { render json: @charge }
    end
  end

  # GET /charges/new
  # GET /charges/new.json
  def new
    @charge = Charge.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @charge }
    end
  end

  # GET /charges/1/edit
  def edit
    @charge = Charge.find(params[:id])
  end

  # POST /charges
  # POST /charges.json
  def create
    if session[:cart_id].present?
      current_cart @customer
    end
    @cart = Cart.find params[:charge][:cart_id]
    
    # check if all items are in stock
    # commented for now
    # @cart.items.each { |item| raise OutOfStockError unless item.is_in_stock? }
    
    if params[:chosen_card_id]
      @credit_card = CreditCard.find params[:chosen_card_id]
      
      if @credit_card.customer != current_customer
        raise "seems like its not your credit card"
      end
    end
    
    if params[:chosen_address_id]
      current_cart.update_attribute :shipping_address_id, params[:chosen_address_id]
    end
    
    params[:charge][:amount] = @cart.subtotal_after_coupon * 100
    
    @charge = Charge.new(params[:charge])

    respond_to do |format|
      if @charge.save
        begin
          if params[:chosen_card_id]
            stripe_customer = Stripe::Customer.retrieve(@credit_card.stripe_customer_id)
            stripe_charge = Stripe::Charge.create(
              :amount => @charge.amount,
              :currency => "usd",
              :customer => stripe_customer.id,
              :description => "cart ##{session[:cart_id]}"
            )
          elsif params[:save_card]
            identifier = current_customer.andand.email
            identifier ||= "cart #{@charge.cart_id}"
            stripe_customer = Stripe::Customer.create(:description => "Customer record for #{identifier}.\n#{params[:company]}\n#{params[:phone]}", :card => @charge.token)
            
            stripe_charge = Stripe::Charge.create(
              :amount => @charge.amount,
              :currency => "usd",
              :customer => stripe_customer.id,
              :description => "cart ##{session[:cart_id]}"
            )
            if current_customer
              current_customer.credit_cards.create :stripe_customer_id => stripe_customer.id
            end
          else
            stripe_charge = Stripe::Charge.create(
              :amount => @charge.amount,
              :currency => "usd",
              :card => @charge.token,
              :description => "cart ##{session[:cart_id]}"
            )
          end
        rescue Stripe::CardError => card_error
          Rails.logger.info card_error.inspect
          @notice = card_error.message
        else
          current_cart.update_attributes :ip_address => request.remote_ip, :status => 1
          session[:cart_id] = nil
          @charge.update_attribute :result, 'complete'
          @cart.update_inventory
          @notice = 'Your order is complete and will ship within a few business days.  Thank you for supporting Little Hippie!'
          begin
            Receipt.purchase_receipt(@charge, stripe_customer).deliver
            OrderMailer.notify_retailer(@cart, stripe_customer).deliver
          rescue Net::SMTPFatalError, ArgumentError => e
            Rails.logger.error e.message
          end
        end
        format.html { redirect_to @charge, notice: @notice }
        format.json { render json: @charge, status: :created, location: @charge }
      else
        format.html { render action: "new" }
        format.json { render json: @charge.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /charges/1
  # PUT /charges/1.json
  def update
    @charge = Charge.find(params[:id])

    respond_to do |format|
      if @charge.update_attributes(params[:charge])
        format.html { redirect_to @charge, notice: 'Charge was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @charge.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /charges/1
  # DELETE /charges/1.json
  def destroy
    @charge = Charge.find(params[:id])
    @charge.destroy

    respond_to do |format|
      format.html { redirect_to charges_url }
      format.json { head :no_content }
    end
  end
end

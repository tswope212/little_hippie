class WishlistItemsController < ApplicationController
  before_filter :authenticate_customer!, :only => [:update, :destroy]
  # GET /wishlist_items
  # GET /wishlist_items.json
  def index
    @wishlist_items = WishlistItem.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @wishlist_items }
    end
  end

  # GET /wishlist_items/1
  # GET /wishlist_items/1.json
  def show
    @wishlist_item = WishlistItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @wishlist_item }
    end
  end

  # GET /wishlist_items/new
  # GET /wishlist_items/new.json
  def new
    @wishlist_item = WishlistItem.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @wishlist_item }
    end
  end

  # GET /wishlist_items/1/edit
  def edit
    @wishlist_item = WishlistItem.find(params[:id])
  end

  # POST /wishlist_items
  # POST /wishlist_items.json
  def create
    if current_customer
      @wishlist_item = WishlistItem.new(params[:wishlist_item])
      @wishlist_item.wishlist = current_customer.primary_wishlist
      if params[:removing_from_cart]
        @deleted_item = current_cart.items.find_by_product_color_id_and_size_id(@wishlist_item.product_color_id, @wishlist_item.size_id)
        @deleted_item.destroy
      end
    end
    
    respond_to do |format|
      if @wishlist_item.andand.save
        format.js
        format.html { redirect_to @wishlist_item, notice: 'Wishlist item was successfully created.' }
        format.json { render json: @wishlist_item, status: :created, location: @wishlist_item }
      else
        format.js   { render action: 'not_added' }
        format.html { render action: "new" }
        format.json { render json: @wishlist_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /wishlist_items/1
  # PUT /wishlist_items/1.json
  def update
    @wishlist_item = WishlistItem.find(params[:id])

    respond_to do |format|
      if @wishlist_item.update_attributes(params[:wishlist_item])
        format.html { redirect_to @wishlist_item, notice: 'Wishlist item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @wishlist_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /wishlist_items/1
  # DELETE /wishlist_items/1.json
  def destroy
    @wishlist_item = WishlistItem.find(params[:id])
    @wishlist_item.destroy

    respond_to do |format|
      format.html { redirect_to wishlist_items_url }
      format.json { head :no_content }
    end
  end
end

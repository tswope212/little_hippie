class ApplicationController < ActionController::Base
  include Facebooker2::Rails::Controller
  protect_from_forgery
  before_filter :meta_description_for_page
  
  helper_method :current_cart, :liked_products, :liked_designs, :liked_banners, :liked_bulletins, :facebook_thumbnail_for_page
  
  def current_cart(give_to_customer = nil)
    @cart = Cart.find_by_id session[:cart_id]
    if @cart.present? && @cart.unpurchased?
      if give_to_customer
        @cart.update_attribute :customer_id, current_customer.id
      end
    elsif current_customer
      @cart = Cart.create :customer => current_customer, :shipping_method => Cart::STANDARD_SHIPPING
      session[:cart_id] = @cart.id
    end
    @cart
  end
  
  def liked_products
    if current_customer
      current_customer.liked_product_ids
    else
      (session[:liked_product_ids] || []).map(&:to_i)
    end
  end
  
  def liked_designs
    if current_customer
      current_customer.liked_design_ids
    else
      (session[:liked_design_ids] || []).map(&:to_i)
    end
  end
  
  def liked_banners
    if current_customer
      current_customer.liked_banner_ids
    else
      (session[:liked_banner_ids] || []).map(&:to_i)
    end
  end
  
  def liked_bulletins
    if current_customer
      current_customer.liked_bulletin_ids
    else
      (session[:liked_bulletin_ids] || []).map(&:to_i)
    end
  end
  
  def facebook_thumbnail_for_page
    case controller_name
    when 'products'
      case action_name
      when 'detail'
        @product.primary_image
      else
        Design.last.art_url
      end
    when 'designs'
      case action_name
      when 'detail'
        @design.art_url
      else
        Design.last.art_url
      end
    when 'banners'
      case action_name
      when 'display'
        @banner.image_url
      else
        Design.last.art_url
      end
    else
      Design.last.art_url
    end
  end
  
  def meta_description_for_page
    if controller_name == 'categories' && action_name == 'show'
      usable_id = Category.find_by_slug(params[:id]).id
    else
      usable_id = params[:id]
    end
    @md_object = if params[:id]
      MetaDescription.find_by_controller_and_action_and_resource_id(controller_name, action_name, usable_id) ||
      MetaDescription.find_by_controller_and_action_and_resource_id(controller_name, action_name, nil)
    else
      MetaDescription.find_by_controller_and_action_and_resource_id controller_name, action_name, nil
    end
    @meta_description = @md_object.andand.description
    @meta_keywords = @md_object.andand.keywords
    @meta_og_image = @md_object.andand.og_image
  end
end

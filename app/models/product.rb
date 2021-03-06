class Product < ActiveRecord::Base
  belongs_to :design
  belongs_to :body_style
  belongs_to :landing_color, :class_name => 'Color'
  has_many :categories, :through => :body_style
  has_many :product_colors, :dependent => :destroy
  has_many :product_images, :through => :product_colors
  has_many :colors, :through => :product_colors
  has_many :sizes, :through => :body_style
  has_many :stocks, :through => :product_colors, :conditions => 'stocks.color_id = product_colors.color_id'
  has_many :garments, :through => :stocks, :conditions => 'garments.design_id = products.design_id'
  has_many :inventory_snapshots, :through => :garments, :conditions => ['inventory_snapshots.current = ?', true]
  has_many :stashed_inventories, :through => :garments
  has_many :inventories, :through => :product_colors
  has_many :friend_emails
  has_many :comments
  has_many :likes, :as => :favorite
  has_many :coupon_products
  has_many :coupons, :through => :coupon_products
  has_many :category_product_features, :through => :product_colors
  has_many :body_style_product_features, :through => :product_colors
  attr_accessible :design_id, :body_style_id, :price, :active, :code, :copy, :open_graph_id
  scope :active, {:conditions => {:active => true}}
  scope :inactive, {:conditions => {:active => false}}
  before_create :use_base_price, :generate_code, :default_to_active
  acts_as_list
  scope :ordered, :order => :position
  scope :alphabetical, order('designs.name, body_styles.name').joins(:design, :body_style)
  scope :with_body_styles, lambda { |body_styles| where(:body_style_id => [body_styles.map(&:id)]) }
  scope :with_design, lambda { |design| where(:design_id => design.id) }
  scope :inventory_order, joins(:design, :body_style).order('designs.code', 'body_styles.position')
  delegate :age_group, :cut_type, :to => :body_style
  
  validates_uniqueness_of :design_id, :scope => :body_style_id
  
  define_index do
    indexes design.name
    indexes design.number
    indexes body_style.name
    indexes body_style.code
    indexes code
  end
  
  def name
    design.name + ' ' + body_style.name
  end
  
  def url_name
    name.gsub(/[\s\?\'\/]/, '-')
  end
  
  def to_param
    "#{id}-#{url_name}"
  end
  
  def art size = nil
    design.art_url size
  end
  
  def generate_code
    self.code = "#{body_style.code}-#{design.number}"
  end
  
  def primary_image size = nil
    if product_images.last
      begin
        product_images.newest.first.image_url(size)
      rescue ArgumentError
        product_images.newest.first.image_url
      end
    else
      begin
        art(size)
      rescue ArgumentError
        art
      end
    end
  end
  
  def landing_product_color
    product_colors.find_by_color_id(landing_color_id) || product_colors.first
  end
  
  def use_base_price
    self.price = body_style.base_price if price.blank?
  end
  
  def dollar_price
    price.andand./(100.0)
  end
  
  def size_price size
    if size == Size.xxl && body_style.xxl_price.andand.>(0)
      body_style.xxl_price / 100.0
    elsif size == Size.xxxl && body_style.xxxl_price.andand.>(0)
      body_style.xxxl_price / 100.0
    else
      dollar_price
    end
  end
  
  def similar_items
    ((body_style.products.active +
    Product.active.with_body_styles(age_group.andand.body_styles.to_a).with_design(design) +
    Product.active.with_body_styles(cut_type.andand.body_styles.to_a).with_design(design) +
    design.products.active).uniq - [self]).sort_by { rand }
  end
  
  def default_to_active
    self.active = true
  end
  
  def random_color
    colors.sample
  end
  
  def number_in_stock
    inventory_snapshots.sum(:current_amount)
  end
  
  def stashed?
    stashed_inventories.present?
  end
  
  def number_in_stock_legacy_inventory_system
    inventories.sum(:amount)
  end
end

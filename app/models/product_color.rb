class ProductColor < ActiveRecord::Base
  belongs_to :product
  has_one :design, :through => :product
  has_one :body_style, :through => :product
  belongs_to :color
  has_many :inventories
  has_many :product_images
  has_many :category_product_features
  has_many :categories, :through => :product
  attr_accessible :product_id, :color_id, :og_code
  validates_presence_of :product_id, :color_id
  validates_uniqueness_of :color_id, :scope => :product_id
  after_create :add_to_category_features
  
  define_index do
    indexes design.name
    indexes design.number
    indexes body_style.name
    indexes body_style.code
    indexes color.name
    indexes color.code
  end
  
  def name
    product.name + " in " + color.name
  end
  
  def code
    "#{product.code}-#{color.code}"
  end
  
  def image
    product_images.last.andand.image
  end
  
  def in_inventory
    inventories.sum(:amount)
  end
  
  def add_to_category_features
    if product.product_colors.map(&:category_product_features).flatten.empty?
      categories.each do |c|
        feature = category_product_features.create :category_id => c.id
        feature.move_to_top
      end
    end
  end
end

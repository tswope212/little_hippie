class CategoryProductFeature < ActiveRecord::Base
  belongs_to :category
  belongs_to :product_color
  attr_accessible :position, :category_id, :product_color_id
  
  scope :by_category, order(:category_id).order(:position)
  
  acts_as_list :scope => :category_id
  
  def name
    "Featured #{position.ordinalize} in #{category.name}"
  end
end

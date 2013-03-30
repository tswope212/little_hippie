class DesignFeature < ActiveRecord::Base
  belongs_to :design
  attr_accessible :active_from, :active_until, :business_manager_id, :position, :design_id
  acts_as_list
  scope :ordered, order(:position)
end

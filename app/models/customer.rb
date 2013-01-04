class Customer < ActiveRecord::Base
  has_many :carts
  has_many :charges, :through => :carts
  has_many :credit_cards
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body
  
  def name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}"
    else
      email
    end
  end
end

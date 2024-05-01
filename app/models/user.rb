class User < ApplicationRecord
  acts_as_paranoid
  belongs_to :client, optional: true
  has_many :identities
  has_many :chatbots, dependent: :nullify
  has_many :user_chatbots, dependent: :destroy
  has_one :instagram_account, dependent: :destroy
  has_many :message_groups, dependent: :destroy
  has_many :user_files, dependent: :destroy
  has_many :payment_gateways, dependent: :destroy
  has_many :user_products, dependent: :destroy
  has_many :products, through: :user_products
  has_many :cart_systems
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :trackable,
         :omniauthable, :omniauth_providers => [:facebook]

  enum role: [:admin_deel, :admin_client, :client]

  validates :client, presence: true
  validates :email, presence: true, uniqueness: true

  def self.from_omniauth auth
    find_or_create_by email: auth.info.email do |user|
      full_name = auth.info.name

      user.email = auth.info.email
      user.full_name = full_name
      user.role = :client
      user.password = Devise.friendly_token[0, 20]
      user.skip_confirmation!
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["address", "business_division", "can_read", "can_write", "client_id", "company_name", "created_at", "current_sign_in_at", "current_sign_in_ip", "deleted_at", "department", "email", "encrypted_password", "english_name", "full_name", "id", "job_title", "language", "last_sign_in_at", "last_sign_in_ip", "phone_number", "post_code", "remember_created_at", "reset_password_sent_at", "reset_password_token", "role", "sign_in_count", "updated_at", "url", "cart_payment_system_id", "shop_name"]
  end
end

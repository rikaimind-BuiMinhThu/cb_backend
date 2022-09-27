class User < ApplicationRecord
  acts_as_paranoid
  belongs_to :client, optional: true
  has_many :identities
  has_many :chatbots, dependent: :nullify
  has_many :user_chatbots, dependent: :destroy
  has_one :instagram_account, dependent: :destroy
  has_many :message_groups, dependent: :destroy
  has_many :emails
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
end

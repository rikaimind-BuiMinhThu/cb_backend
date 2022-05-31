class User < ApplicationRecord
  acts_as_paranoid
  belongs_to :client, optional: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]


  enum role: [:admin_deel, :admin_client, :client]

  has_many :identities

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

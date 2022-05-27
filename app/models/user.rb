class User < ApplicationRecord
  belongs_to :client
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable

  enum role: [:admin_deel, :admin_client, :client]
end

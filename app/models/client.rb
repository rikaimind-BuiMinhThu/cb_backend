class Client < ApplicationRecord
  acts_as_paranoid
  has_many :users

  after_destroy :update_users_with_old_client

  enum status: {active: 0, pause: 1, ended: 2, trial: 3}
  enum plan: {startup: 0, premium: 1, expert: 2}


  private

  def update_users_with_old_client
    users = User.where(client_id: self.id)
    users.update_all client_id: nil
  end
end

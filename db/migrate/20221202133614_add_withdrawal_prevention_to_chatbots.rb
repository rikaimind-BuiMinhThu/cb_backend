class AddWithdrawalPreventionToChatbots < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :withdrawal_prevention_status, :integer, default: 0
    add_column :chatbots, :withdrawal_prevention_image_url, :string
    add_column :chatbots, :withdrawal_prevention_link_url, :string
  end
end

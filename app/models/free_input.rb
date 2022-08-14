class FreeInput < ApplicationRecord
  belongs_to :message
  has_many :free_input_labels, dependent: :destroy

  enum format_check: {no_validate: 0, email: 1, phone_number: 2, real_name: 3, company_name: 4, company_role: 5, website: 6, propose: 7, know_product_in: 8}, _prefix: :format_check

  def need_pending_check?
    format_check_email? || format_check_phone_number?
  end
end

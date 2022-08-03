class FreeInput < ApplicationRecord
  belongs_to :message
  has_many :free_input_labels

  enum format_check: {no_validate: 0, email: 1, phone_number: 2}, _prefix: :format_check

  def need_pending_check?
    format_check_email? || format_check_phone_number?
  end
end

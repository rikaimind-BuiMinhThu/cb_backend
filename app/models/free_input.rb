class FreeInput < ApplicationRecord
  belongs_to :message
  belongs_to :message_bag
  has_many :free_input_labels

  enum format_check: {no_validate: 0, email: 1, phone_number: 2}
end

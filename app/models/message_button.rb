class MessageButton < ApplicationRecord
  belongs_to :message
  belongs_to :message_bag, optional: true
  has_many :message_button_labels, dependent: :destroy

  enum button_type: {mess: 0, web_url: 1}
  enum is_purchase_button: {yes: true, no: false}, _prefix: :is_purchase_button
end

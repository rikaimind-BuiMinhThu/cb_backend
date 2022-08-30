class MessageButton < ApplicationRecord
  URL_REG = /\A(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})\z/

  belongs_to :message
  belongs_to :message_bag, optional: true
  has_many :message_button_labels, dependent: :destroy

  enum button_type: {mess: 0, web_url: 1}
  enum is_purchase_button: {yes: true, no: false}, _prefix: :is_purchase_button

  # validates :content, presence: true
  validates :content, allow_blank: true, format: URL_REG, if: -> {web_url?}
end

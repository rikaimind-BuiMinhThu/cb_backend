class HistoryClickUrl < ApplicationRecord
  URL_REG = /\A(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})\z/
  SHORTEN_CODE_LENGTH = 9

  belongs_to :chatbot

  before_validation :generate_shorten_code, on: :create

  validates :num_of_click, presence: true
  validates :origin_url, presence: true, format: URL_REG
  validates_format_of :origin_url, without: /#{Settings.api.shorten_url}/i
  validates :shorten_code, presence: true

  private

  def generate_shorten_code
    return if self.shorten_code.present?
    shorten_temp = SecureRandom.alphanumeric(SHORTEN_CODE_LENGTH)
    while HistoryClickUrl.find_by(shorten_code: shorten_temp).present?
      shorten_temp = SecureRandom.alphanumeric(SHORTEN_CODE_LENGTH)
    end
    self.shorten_code = shorten_temp
  end
end

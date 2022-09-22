class UserChatbot < ApplicationRecord
  belongs_to :user
  belongs_to :chatbot

  enum role: {bot_admin: 0, editor: 1, reader: 2}

  validates :user, uniqueness: { scope: :chatbot }
end

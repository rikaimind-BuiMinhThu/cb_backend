class MessageButton < ApplicationRecord
  belongs_to :message

  enum button_type: {mess: 0, web_url: 1}
end

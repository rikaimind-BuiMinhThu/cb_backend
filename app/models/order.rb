class Order < ApplicationRecord
  enum bot_type: {instagram: 0, web: 1, line: 2, tiktok: 3}
end

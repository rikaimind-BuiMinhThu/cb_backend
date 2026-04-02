class ShopifyAccessToken < ApplicationRecord
  belongs_to :client

  TOKEN_REFRESH_THRESHOLD = 80000 

  def expired?
    self.expires_at.present? && self.expires_at < Time.current
  end

  def should_refresh?
    self.issued_at.present? && (Time.current - self.issued_at) >= TOKEN_REFRESH_THRESHOLD
  end

  def valid_tokens?
    admin_token.present? && storefront_token.present? && !expired? && !should_refresh?
  end
end

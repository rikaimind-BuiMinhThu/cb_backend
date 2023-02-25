class TamagoRepeatConfig < ApplicationRecord
  belongs_to :scenario

  enum email_confirm_field: {
    email_confirm_none: 0,
    email_confirm_optional: 1,
    email_confirm_required: 2
  }

  enum name_kana_field: {
    name_kana_none: 0,
    name_kana_optional: 1,
    name_kana_required: 2
  }
end

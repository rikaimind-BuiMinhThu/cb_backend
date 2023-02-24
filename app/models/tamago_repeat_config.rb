class TamagoRepeatConfig < ApplicationRecord
  belongs_to :scenario

  enum email_confirm_field: {
    none_email_confirm: 0,
    optional_email_confirm: 1,
    required_email_confirm: 2
  }

  enum name_kana_field: {
    none_name_kana: 0,
    optional_name_kana: 1,
    required_name_kana: 2
  }
end

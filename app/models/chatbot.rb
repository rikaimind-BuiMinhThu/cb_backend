class Chatbot < ApplicationRecord
  has_many :user_chatbots, dependent: :destroy
  has_many :users, through: :user_chatbots
  has_many :emails, dependent: :destroy
  has_many :variables, dependent: :destroy
  has_many :scenarios, dependent: :destroy
  has_many :push_messages, dependent: :destroy
  has_many :history_click_urls, dependent: :destroy
  has_many :specify_payment_variables, dependent: :destroy
  has_many :settlement_fee_variables, dependent: :destroy
  has_many :shipping_fee_variables, dependent: :destroy
  has_many :np_value_settlements, dependent: :destroy
  has_many :sms_templates, dependent: :destroy
  has_many :push_message_histories, dependent: :destroy

  belongs_to :user
  belongs_to :specify_payment_variable, class_name: Variable.name, optional: true
  belongs_to :settlement_fee_variable, class_name: Variable.name, optional: true
  belongs_to :shipping_fee_variable, class_name: Variable.name, optional: true

  accepts_nested_attributes_for :np_value_settlements

  enum design_type: {pop: 0, flat: 1, material: 2}
  enum main_color: {pink: 0, yellow: 1, orange: 2, blue: 3, green: 4, purple: 5, black: 6, white: 7}
  enum status: {off: 0, on: 1}, _prefix: true
  enum include_tax: {internal_tax: false, foreign_tax: true}
  enum sale_tax_rate: {eight_percent: 0, ten_percent: 1}
  enum calculate_one_yen: {truncation: false, rounded_up: true}
  enum can_specify_payment: {no: false, yes: true}, _prefix: true
  enum need_paid_settlement_fee: {free: false, paid: true}, _prefix: true
  enum need_paid_shipping_fee: {free: false, paid: true}, _prefix: true
  enum need_np_deferred_payment: {no: false, yes: true}, _prefix: true
  enum np_invoice_included: {not_include: 0, enclosed: 1}, _prefix: true
  enum withdrawal_prevention_status: {invalid: 0, standard_exit_popup: 1, image_popup: 2}, _prefix: true

  mount_base64_uploader :icon, ChatbotIconUploader
  mount_base64_uploader :opening_bot_icon, ChatbotOpeningBotIconUploader
  mount_base64_uploader :closing_bot_icon, ChatbotClosingBotIconUploader

  validates :title, presence: true
  validates :subtitle, presence: true
  validates :design_type, presence: true
  # validates :main_color, presence: true
  validates :status, presence: true
  validates :bot_name, presence: true
  validates :np_maximum_amount, presence: true, if: -> {need_np_deferred_payment_yes?}
  validates :np_value_settlements, presence: true, if: -> {need_np_deferred_payment_yes?}
  validates :withdrawal_prevention_image_url, presence: true, if: -> {withdrawal_prevention_status_image_popup?}

  def self.ransackable_attributes(auth_object = nil)
    ["bot_name", "calculate_one_yen", "can_specify_payment", "created_at", "design_settings", "design_type", "icon", "opening_bot_icon", "closing_bot_icon", "id", "include_tax", "main_color", "need_np_deferred_payment", "need_paid_settlement_fee", "need_paid_shipping_fee", "np_invoice_included", "np_maximum_amount", "sale_tax_rate", "scenario_selected", "settlement_fee_variable_id", "shipping_fee_variable_id", "specify_payment_variable_id", "status", "subtitle", "title", "updated_at", "user_id", "withdrawal_prevention_image_url", "withdrawal_prevention_link_url", "withdrawal_prevention_status"]
  end
end

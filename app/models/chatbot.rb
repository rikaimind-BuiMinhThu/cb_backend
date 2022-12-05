class Chatbot < ApplicationRecord
  has_many :user_chatbots, dependent: :destroy
  has_many :users, through: :user_chatbots
  has_many :emails, through: :user_chatbots
  has_many :variables, dependent: :destroy
  has_many :scenarios, dependent: :destroy
  has_many :push_messages, dependent: :destroy
  has_many :history_click_urls, dependent: :destroy
  has_many :specify_payment_variables, dependent: :destroy
  has_many :settlement_fee_variables, dependent: :destroy
  has_many :shipping_fee_variables, dependent: :destroy
  has_many :np_value_settlements, dependent: :destroy

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

  validates :title, presence: true
  validates :subtitle, presence: true
  validates :design_type, presence: true
  validates :main_color, presence: true
  validates :status, presence: true
  validates :bot_name, presence: true
  validates :np_maximum_amount, presence: true, if: -> {need_np_deferred_payment_yes?}
  validates :np_value_settlements, presence: true, if: -> {need_np_deferred_payment_yes?}
  validates :withdrawal_prevention_image_url, presence: true, if: -> {withdrawal_prevention_status_image_popup?}
end

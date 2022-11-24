json.code 1
json.data do
  json.id @chatbot.id
  json.include_tax @chatbot.include_tax
  json.sale_tax_rate @chatbot.sale_tax_rate
  json.calculate_one_yen @chatbot.calculate_one_yen
  json.can_specify_payment @chatbot.can_specify_payment
  json.specify_payment_variable do
    json.id @chatbot.specify_payment_variable&.id
    json.variable_name @chatbot.specify_payment_variable&.variable_name
  end
  json.specify_payment_variables @chatbot.specify_payment_variables.each do |specify_payment_variable|
    json.variable_value specify_payment_variable.variable_value
    json.payment_gateway_id specify_payment_variable.payment_gateway_id
    json.payment_gateway_name specify_payment_variable.payment_gateway.gateway_name
  end
  json.need_paid_settlement_fee @chatbot.need_paid_settlement_fee
  # json.settlement_fee_variable @chatbot.settlement_fee_variable
  json.settlement_fee_variable do
    json.id @chatbot.settlement_fee_variable&.id
    json.variable_name @chatbot.settlement_fee_variable&.variable_name
  end
  json.settlement_fee_variables @chatbot.settlement_fee_variables do |settlement_fee_variable|
    json.variable_value settlement_fee_variable.variable_value
    json.commission settlement_fee_variable.commission
  end
  json.need_paid_shipping_fee @chatbot.need_paid_shipping_fee
  json.shipping_fee_variable do
    json.id @chatbot.shipping_fee_variable&.id
    json.variable_name @chatbot.shipping_fee_variable&.variable_name
  end
  json.shipping_fee_variables Prefecture.all.each do |prefecture|
    json.prefecture_id prefecture.id
    json.prefecture_name prefecture.name
    json.value @chatbot.shipping_fee_variables.find_by(prefecture: prefecture)&.amount || 0
  end
end

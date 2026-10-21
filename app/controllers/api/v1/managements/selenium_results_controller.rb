class Api::V1::Managements::SeleniumResultsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    return render json: { code: 2, message: "No permission" } unless current_user&.admin_deel? || current_user&.admin_client?
    return render json: { code: 2, message: "not lexica" }, status: 403 unless lexica_client?

    results = base_scope
    results = results.where(result: params[:result]) if params[:result].present?
    results = results.where(path: params[:path]) if params[:path].present?
    if params[:start_date].present?
      results = results.where("DATE(created_at) >= ?", params[:start_date].to_date)
    end
    if params[:end_date].present?
      results = results.where("DATE(created_at) <= ?", params[:end_date].to_date)
    end
    total = results.count
    results = results.order(created_at: :desc).page(params[:page])
    render json: { code: 1, data: results.map { |row| list_json(row) }, total: total }
  end

  def show
    return render json: { code: 2, message: "No permission" } unless current_user&.admin_deel? || current_user&.admin_client?
    return render json: { code: 2, message: "not lexica" }, status: 403 unless lexica_client?

    row = base_scope.find_by(id: params[:id])
    return render json: { code: 2, message: "not found" } if row.blank?

    answers = ScenarioUserResponse.where(scenario_id: row.scenario_id, user_input_id: row.user_input_id)
    render json: { code: 1, data: detail_json(row, answers) }
  end

  def screenshot
    return render json: { code: 2, message: "No permission" } unless current_user&.admin_deel? || current_user&.admin_client?
    return render json: { code: 2, message: "not lexica" }, status: 403 unless lexica_client?

    row = base_scope.find_by(id: params[:id])
    return render json: { code: 2, message: "not found" }, status: :not_found if row.blank? || !screenshot_available?(row)

    send_data AmazonWebServices::RpaScreenshotS3.read(row.screenshot_path), type: "image/png", disposition: "inline"
  end

  private

  def screenshot_available?(row)
    AmazonWebServices::RpaScreenshotS3.s3_key?(row.screenshot_path)
  end

  def lexica_client?
    client&.lexica?
  end

  def client
    @client ||= if current_user.admin_deel?
      Chatbot.find_by(id: requested_chatbot_id)&.user&.client ||
        current_user.client
    else
      current_user.client
    end
  end

  def base_scope
    ScenarioUserResponseSeleniumResult.for_listing(
      chatbot_id: requested_chatbot_id,
      client_id: listing_client_id
    )
  end

  def requested_chatbot_id
    params[:chatbot_id].presence || params[:bot_id].presence
  end

  def listing_client_id
    return client.id if client
    return current_user.client_id if requested_chatbot_id.blank? && current_user.admin_client?

    nil
  end

  def list_json(row)
    {
      id: row.id,
      created_at: row.created_at,
      start_time: row.start_time,
      end_time: row.end_time,
      result: row.result,
      path: row.path,
      path_label: row.path_label,
      payment: row.payment,
      payment_label: row.payment_label,
      email: email_for(row),
      sku: row.sku,
      lexica_order_id: row.lexica_order_id,
      last_step_description: row.last_step_description,
      scenario_id: row.scenario_id,
      user_input_id: row.user_input_id,
      chrome_slot_defer_count: row.chrome_slot_defer_count,
      chrome_slot_retry_count: row.chrome_slot_retry_count
    }
  end

  def detail_json(row, answers)
    list_json(row).merge(
      product_url: row.product_url,
      cart_url: row.cart_url,
      start_time: row.start_time,
      end_time: row.end_time,
      error_kind: row.error_kind,
      error_message: row.error_message,
      screenshot_path: row.screenshot_path,
      has_screenshot: screenshot_available?(row),
      masked_pan: row.masked_pan,
      card_expiry: row.card_expiry,
      card_holder: row.card_holder,
      rpa_steps: row.rpa_steps_array,
      answers: answers_json(row, answers)
    )
  end

  def answers_json(row, answers)
    names = if row.path.to_s == "existing"
      %w[user_email email]
    else
      %w[user_email email user_name user_name_kana zip_code_address phone_number phone birth_date]
    end
    answers.select { |a| names.include?(a.data_input_name.to_s) }.map do |a|
      { data_input_name: a.data_input_name, value: redact_answer(a) }
    end
  end

  def redact_answer(answer)
    return "********" if answer.data_input_name.to_s == "password"

    answer.value
  end

  def email_for(row)
    ScenarioUserResponse.where(scenario_id: row.scenario_id, user_input_id: row.user_input_id, data_input_name: %w[user_email email]).last&.value
  end
end

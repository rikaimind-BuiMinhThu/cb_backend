class Api::V1::ChatbotSettings::WithdrawalPreventionsController < ApplicationController
  def show
    chatbot = find_chatbot
    return if chatbot.blank?
    render json: {
      code: 1,
      data: {
        withdrawal_prevention_status: chatbot.withdrawal_prevention_status,
        withdrawal_prevention_image_url: chatbot.withdrawal_prevention_image_url,
        withdrawal_prevention_link_url: chatbot.withdrawal_prevention_link_url
      }
    }
  end

  def update
    chatbot = find_chatbot(true)
    return if chatbot.blank?
    return render json: {code: 1, message: "Success"} if chatbot.update(withdrawal_prevention_params)
    render json: {code: 2, data: chatbot.errors.full_messages}
  end

  private

  def withdrawal_prevention_params
    params.require(:withdrawal_prevention).permit(:withdrawal_prevention_status, :withdrawal_prevention_image_url, :withdrawal_prevention_link_url)
  end

  def find_chatbot(editor_permission = false)
    render json: {code: 2, message: "No permission"} and return unless current_user.admin_deel? || current_user.admin_client?
    chatbot = Chatbot.find_by(id: params[:id])
    render json: {code: 2, message: "Cannot find chatbot"} and return if chatbot.blank?
    chatbot_roles = [:bot_admin, :editor]
    chatbot_roles.push(:reader) if editor_permission.blank?
    render json: {code: 2, message: "No permission"} and return if current_user.admin_client? && chatbot.user_chatbots.where(role: chatbot_roles).pluck(:user_id).exclude?(current_user.id)
    chatbot
  end
end

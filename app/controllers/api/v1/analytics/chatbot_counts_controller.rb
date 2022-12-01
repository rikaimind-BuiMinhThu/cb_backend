class Api::V1::Analytics::ChatbotCountsController < ApplicationController
  def show
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find chatbot"} if chatbot.blank?
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel? || current_user.admin_client?
    return render json: {code: 2, data: "No permission"} if current_user.admin_client? && chatbot.user_chatbots.where(role: [:bot_admin, :editor, :reader]).pluck(:user_id).exclude?(current_user.id)
    render json: {code: 1, data: {chatbot: {num_of_pc_count: chatbot.num_of_pc_count, num_of_tablet_count: chatbot.num_of_tablet_count, num_of_sp_count: chatbot.num_of_sp_count, num_of_conversion_count: chatbot.num_of_conversion_count, num_of_open_chatbot_window_count: chatbot.num_of_open_chatbot_window_count}}}
  end

  def update
    chatbot = Chatbot.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find chatbot"} if chatbot.blank?
    chatbot_data = params[:chatbot_data]
    return render json: {code: 2, message: "Invalid chatbot data"} if ["pc", "tablet", "sp", "conversion", "open_chatbot_window"].exclude?(chatbot_data)
    # this will become chatbot.num_of_{chatbot_data}_count = chatbot.num_of_{chatbot_data}_count + 1
    chatbot.send("num_of_#{chatbot_data}_count=".to_sym, chatbot.send("num_of_#{chatbot_data}_count".to_sym) + 1)
    return render json: {code: 1, message: "Success"} if chatbot.save
    render json: {code: 2, message: chatbot.errors.full_messages}
  end
end

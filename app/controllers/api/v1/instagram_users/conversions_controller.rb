class Api::V1::InstagramUsers::ConversionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if @instagram_user.blank?
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && @instagram_user.instagram_account == current_user.instagram_account)
    conversions = instagram_user.conversions
    render json: {code: 1, data: conversions}
  end
end

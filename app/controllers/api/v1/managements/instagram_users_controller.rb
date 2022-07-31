class Api::V1::Managements::InstagramUsersController < ApplicationController
  def index
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || current_user.admin_client?
    @instagram_users = InstagramUser.all
    @instagram_users = @instagram_users.where(instagram_account: current_user.instagram_account) if current_user.admin_client?
  end

  def show
    @instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if user.blank?
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && @instagram_user.instagram_account == current_user.instagram_account)
  end
end

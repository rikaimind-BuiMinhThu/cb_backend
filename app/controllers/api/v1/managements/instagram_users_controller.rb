class Api::V1::Managements::InstagramUsersController < ApplicationController
  def index
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel? || current_user.admin_client?
    @instagram_users = InstagramUser.all

    if params[:instagram_user_name].present?
      @instagram_users = @instagram_users.where("username like ?", "%#{params[:instagram_user_name]}%")
    end

    if params[:client_name].present?
      @instagram_users = @instagram_users.joins(instagram_account: [user: :client]).where('clients.name like ?', "%#{params[:client_name]}%")
    end

    if params[:supporting_users] == "true"
      @instagram_users = @instagram_users.joins(:supporting_users).group(:id)
    end

    @instagram_users = @instagram_users.where(instagram_account: current_user.instagram_account) if current_user.admin_client?
    @total = @instagram_users.length
    @instagram_users = @instagram_users.page(params[:page])
  end

  def show
    @instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, message: "Not found"} if @instagram_user.blank?
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && @instagram_user.instagram_account == current_user.instagram_account)
  end

  def update
    @instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, message: "Not found"} if @instagram_user.blank?
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && @instagram_user.instagram_account == current_user.instagram_account)
    @instagram_user.update(instagram_user_param)
    render json: {code: 1, message: "success"}
  end

  private

  def instagram_user_param
    params.require(:instagram_user).permit(:status)
  end
end

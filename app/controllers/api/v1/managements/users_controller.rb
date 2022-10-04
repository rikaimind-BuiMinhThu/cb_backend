class Api::V1::Managements::UsersController < ApplicationController
  def index
    return render json: {code: 2, data: "Not have permission"} if current_user.client?
    q = {full_name_or_email_or_client_name_cont: params[:name], client_id_eq: params[:client_id]} if current_user.admin_deel?
    q = {full_name_or_email_or_client_name_cont: params[:name], client_id_eq: current_user.client_id} if current_user.admin_client?
    @users = User.ransack(q).result(distinct: true).includes(:client)
    @total = @users.size
    @users = @users.order(created_at: :desc).page(params[:page])
    # render json: {code: 1, data: {users: users, total: total}}
  end

  def show
    user = User.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if user.blank?
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || user.client_id == current_user.client_id || user.id == current_user.id
    render json: {code: 1, data: user}
  end

  def update
    user = User.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if user.blank?
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || user.client_id == current_user.client_id || user.id == current_user.id
    if current_user.admin_deel?
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        return render json: {code: 1, data: "Success"} if user.update admin_user_params
      else
        if params[:user][:password] == params[:user][:password_confirmation]
          return render json: {code: 1, data: "Success"} if user.update admin_with_password_user_params
        else
          return render json: {code: 2, data: "Password Confirm not Comparing with Password"}
        end
      end
    end
    return render json: {code: 1, data: user} if user.update user_params
    render json: {code: 2, data: "Fail"}
  end

  def destroy
    return render json: {code: 2, data: "Cannot delete yourself"} if current_user.id == params[:id]
    user = User.find_by(id: params[:id])
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || user.client_id == current_user.client_id || user.id == current_user.id
    return render json: {code: 1, data: "Success"} if user.destroy
    render json: {code: 2, data: "Fail"}
  end

  private

  def user_params
    params.require(:user).permit(:full_name, :english_name, :email, :business_division,
      :company_name, :department, :job_title, :post_code, :address, :language)
  end

  def admin_user_params
    params.require(:user).permit(:full_name, :client_id, :english_name,
      :can_read, :can_write, :email, :business_division, :company_name, :department,
      :job_title, :post_code, :address, :language)
  end

  def admin_with_password_user_params
    params.require(:user).permit(:full_name, :client_id, :english_name,
      :can_read, :can_write, :email, :password, :password_confirmation,
      :business_division, :company_name, :department, :job_title, :post_code,
      :address, :language)
  end
end

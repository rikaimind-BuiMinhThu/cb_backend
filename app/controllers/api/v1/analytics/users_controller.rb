class Api::V1::Analytics::UsersController < ApplicationController
  def index
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    q = {created_at_lteq: params[:to_date].to_datetime, created_at_gteq: params[:from_date].to_datetime}
    q[:client_id_eq] = current_user.client_id if current_user.admin_client?
    user_counts = User.ransack(q).result.count
    render json: {code: 1, user_counts: user_counts}
  end
end

class Api::V1::Analytics::UsersController < ApplicationController
  def index
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    end_date = Date.current
    case params[:date]
    when "5d"
      begin_date = Date.current - 5.days
    when "10d"
      begin_date = Date.current - 10.days
    when "15d"
      begin_date = Date.current - 15.days
    when "30d"
      begin_date = Date.current - 30.days
    when "3m"
      begin_date = (Date.current - 2.months).at_beginning_of_month
    when "6m"
      begin_date = (Date.current - 5.months).at_beginning_of_month
    else
      return render json: {code: 2, message: "Please enter date"}
    end
    q = {created_at_lteq: end_date, created_at_gteq: begin_date}
    q[:client_id_eq] = current_user.client_id if current_user.admin_client?
    user_counts = User.ransack(q).result.count
    if ["3m", "6m"].include?(params[:date])
      user_counts = user_counts.group("DATE_FORMAT(created_at, '%m/%Y')").select("DATE_FORMAT(created_at, '%m/%Y') as log_date, count(*) as user_count")
    else
      user_counts = user_counts.group("DATE_FORMAT(created_at, '%d/%m/%Y')").select("DATE_FORMAT(created_at, '%d/%m/%Y') as log_date, count(*) as user_count")
    end
    render json: {code: 1, user_counts: user_counts}
  end
end

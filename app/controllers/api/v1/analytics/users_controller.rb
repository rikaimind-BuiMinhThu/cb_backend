class Api::V1::Analytics::UsersController < ApplicationController
  def index
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    return render json: {code: 2, message: "Missing begin date"} if params[:begin_date].blank?
    return render json: {code: 2, message: "Missing end date"} if params[:end_date].blank?

    begin_date = params[:begin_date].to_date
    end_date = params[:end_date].to_date

    q = {created_at_lteq: end_date.end_of_day, created_at_gteq: begin_date.beginning_of_day}
    q[:client_id_eq] = current_user.client_id if current_user.admin_client?
    user_counts = User.ransack(q).result
    user_counts = user_counts.group("DATE_FORMAT(created_at, '%d/%m/%Y')").select("DATE_FORMAT(created_at, '%d/%m/%Y') as log_date, count(*) as user_count")
    date_arr = create_date_arr(begin_date, end_date)
    user_counts.each do |date_hash|
      date_arr.map { |x| x[:user_count] = (x[:log_date] == date_hash.log_date) ? date_hash.user_count : x[:user_count] }
    end
    render json: {code: 1, user_counts: date_arr}
  end

  private

  def create_date_arr(start_date, end_date)
    date_arr = []
    (start_date..end_date).each do |datee|
      date_hash = {log_date: datee.strftime("%d/%m/%Y"), user_count: 0}
      date_arr.push(date_hash)
    end
    date_arr
  end
end

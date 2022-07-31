class Api::V1::Analytics::ChatbotUsagesController < ApplicationController
  def show
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    return render json: {code: 2, message: "Invalid parameter"} unless ["message", "user", "live"].include?(params[:id])
    end_date = Time.current
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
    @q = {created_at_lteq: end_date, created_at_gteq: begin_date}
    @q[:instagram_account_eq] = current_user.instagram_account
    return get_stats_live if params[:id] == "live"
    if params[:id] == "user"
      counts = InstagramUser.ransack(@q).result
      if ["3m", "6m"].include?(params[:date])
        counts = counts.group("DATE_FORMAT(created_at, '%m/%Y')").select("DATE_FORMAT(created_at, '%m/%Y') as log_date, count(*) as user_count")
      else
        counts = counts.group("DATE_FORMAT(created_at, '%d/%m/%Y')").select("DATE_FORMAT(created_at, '%d/%m/%Y') as log_date, count(*) as user_count")
      end
    else
      counts = ChatbotUsage.ransack(@q).result
      counts = counts.where(usage_type: [:dm_received, :post_comment_sent, :story_comment_sent, :live_comment_sent])
      if ["3m", "6m"].include?(params[:date])
        counts = counts.group("DATE_FORMAT(created_at, '%m/%Y')").select("DATE_FORMAT(created_at, '%m/%Y') as log_date, count(*) as message_count")
      else
        counts = counts.group("DATE_FORMAT(created_at, '%d/%m/%Y')").select("DATE_FORMAT(created_at, '%d/%m/%Y') as log_date, count(*) as message_count")
      end
    end
    date_arr = create_date_arr(begin_date, end_date)
    counts.each do |date_hash|
      date_arr.map do |x|
        if params[:id] == "user"
          x[:user_count] = (x[:log_date] == date_hash.log_date) ? date_hash.user_count : x[:user_count]
        else
          x[:message_count] = (x[:log_date] == date_hash.log_date) ? date_hash.message_count : x[:message_count]
        end
      end
    end
    render json: {code: 1, counts: date_arr}
  end

  private

  def get_stats_live
    media_ids = ChatbotUsage.live_comment_received.ransack(@q).result.group(:media_id).pluck(:media_id)
    live_usages = []
    media_ids.each do |media_id|
      live_usage = {}
      live_usage[:media_start_at] = ChatbotUsage.live_comment_received.where(media_id: media_id).where.not(media_start_at: nil).first.media_start_at.strftime("%d/%m/%Y %H:%m:%S")
      live_usage[:comment_count] = ChatbotUsage.live_comment_received.where(media_id: media_id).count
      live_usage[:user_count] = ChatbotUsage.live_comment_received.where(media_id: media_id).pluck(:instagram_user_id).uniq.length
      live_usage[:comment_lives] = ChatbotUsage.live_comment_received.where(media_id: media_id).pluck(:content)
      live_usages.push(live_usage)
    end
    render json: {code: 1, live_usages: live_usages}
  end

  def create_date_arr(start_date, end_date)
    date_arr = []
    id_param = params[:id] + "_count"
    if ["3m", "6m"].include?(params[:date])
      count_times = (params[:date] == "3m") ? 3 : 6
      count_times.times do |m|
        date_hash = {log_date: (start_date + m.months).strftime("%m/%Y")}
        date_hash[id_param.to_sym] = 0
        date_arr.push(date_hash)
      end
    else
      (start_date..end_date).each do |datee|
        date_hash = {log_date: datee.strftime("%d/%m/%Y")}
        date_hash[id_param.to_sym] = 0
        date_arr.push(date_hash)
      end
    end
    date_arr
  end
end

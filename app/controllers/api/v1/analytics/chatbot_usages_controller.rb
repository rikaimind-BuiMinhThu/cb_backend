class Api::V1::Analytics::ChatbotUsagesController < ApplicationController
  def show
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    return render json: {code: 2, message: "Invalid parameter"} unless ["message", "user", "live"].include?(params[:id])
    return render json: {code: 2, message: "Missing begin date"} if params[:begin_date].blank?
    return render json: {code: 2, message: "Missing end date"} if params[:end_date].blank?

    begin_date = params[:begin_date].to_date
    end_date = params[:end_date].to_date

    @q = {created_at_lteq: end_date.end_of_day, created_at_gteq: begin_date.beginning_of_day}
    @q[:instagram_account_eq] = current_user.instagram_account
    return get_stats_live if params[:id] == "live"
    if params[:id] == "user"
      counts = InstagramUser.ransack(@q).result
      counts = counts.group("DATE_FORMAT(created_at, '%d/%m/%Y')").select("DATE_FORMAT(created_at, '%d/%m/%Y') as log_date, count(*) as user_count")
    else
      counts = ChatbotUsage.ransack(@q).result
      counts = counts.where(usage_type: [:dm_received, :post_comment_sent, :story_comment_sent, :live_comment_sent])
      counts = counts.group("DATE_FORMAT(created_at, '%d/%m/%Y')").select("DATE_FORMAT(created_at, '%d/%m/%Y') as log_date, count(*) as message_count")
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
    media_ids = ChatbotUsage.live_comment_received.ransack(@q).result
    total = media_ids.length
    media_ids = media_ids.page(params[:page]).per(10).group(:media_id).pluck(:media_id)
    live_usages = []
    media_ids.each do |media_id|
      live_usage = {}
      chatbot_lives = ChatbotUsage.live_comment_received.where(media_id: media_id)
      live_usage[:media_start_at] = chatbot_lives.where.not(media_start_at: nil).first.media_start_at.strftime("%d/%m/%Y %H:%m:%S")
      live_usage[:comment_count] = chatbot_lives.count
      live_usage[:user_count] = chatbot_lives.pluck(:instagram_user_id).uniq.length
      live_usage[:comment_lives] = chatbot_lives.joins(:instagram_user).select(:id, :content, :full_name, "DATE_FORMAT(chatbot_usages.created_at, '%d/%m/%Y %H:%m:%S') as created_at")
      live_usages.push(live_usage)
    end
    render json: {code: 1, live_usages: live_usages, total: total}
  end

  def create_date_arr(start_date, end_date)
    date_arr = []
    id_param = params[:id] + "_count"
    (start_date..end_date).each do |datee|
      date_hash = {log_date: datee.strftime("%d/%m/%Y")}
      date_hash[id_param.to_sym] = 0
      date_arr.push(date_hash)
    end
    date_arr
  end
end

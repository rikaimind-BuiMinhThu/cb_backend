class Api::V1::Analytics::ChatbotUsagesController < ApplicationController
  def show
    return render json: {code: 2, message: "No permission"} unless ["admin_deel", "admin_client"].include?(current_user.role)
    return render json: {code: 2, message: "Invalid parameter"} unless ["message", "user", "live"].include?(params[:id])
    @q = {created_at_lteq: params[:to_date].to_datetime, created_at_gteq: params[:from_date].to_datetime}
    @q[:instagram_account_eq] = current_user.instagram_account if current_user.admin_client?
    return get_stats_live if params[:id] == "live"
    counts = ChatbotUsage.where(usage_type: [:dm_received, :dm_sent, :post_comment_sent, :story_comment_sent, :live_comment_sent]).ransack(@q).result
    counts = (params[:id] == "message") ? counts.count : counts.pluck(:sender_id).uniq.length
    render json: {code: 1, counts: counts}
  end

  private

  def get_stats_live
    media_ids = ChatbotUsage.live_comment_received.ransack(@q).result.group(:media_id).pluck(:media_id)
    live_usages = []
    media_ids.each do |media_id|
      live_usage = {}
      live_usage[:media_start_at] = ChatbotUsage.live_comment_received.where(media_id: media_id).first.media_start_at
      live_usage[:comment_count] = ChatbotUsage.live_comment_received.where(media_id: media_id).count
      live_usage[:user_count] = ChatbotUsage.live_comment_received.where(media_id: media_id).pluck(:sender_id).uniq.length
      live_usages.push(live_usage)
    end
    render json: {code: 1, live_usages: live_usages}
  end
end

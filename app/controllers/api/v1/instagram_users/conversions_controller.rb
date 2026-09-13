class Api::V1::InstagramUsers::ConversionsController < ApplicationController
  skip_before_action :permision, only: [:create]
  skip_before_action :verify_authenticity_token

  CHANNELS = {
    dm: :dm,
    story: :story_comment,
    live: :live_comment
  }.freeze

  def index
    instagram_users = InstagramUser.all
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel? || current_user.admin_client?
    instagram_users = instagram_users.where(instagram_account: current_user.instagram_account)

    begin_date, end_date = parse_date_range
    instagram_users = filter_users_by_created_at(instagram_users, begin_date, end_date)

    stats = build_channel_stats(instagram_users, begin_date, end_date)

    @live_instagram_user_count = stats[:live][:user_count]
    @story_instagram_user_count = stats[:story][:user_count]
    @dm_instagram_user_count = stats[:dm][:user_count]
    @live_instagram_message_count = stats[:live][:message_count]
    @story_instagram_message_count = stats[:story][:message_count]
    @dm_instagram_message_count = stats[:dm][:message_count]
    @live_conversion_count = stats[:live][:conversion_count]
    @story_conversion_count = stats[:story][:conversion_count]
    @dm_conversion_count = stats[:dm][:conversion_count]
  end

  def show
    instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, message: "Not found"} if instagram_user.blank?
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && instagram_user.instagram_account == current_user.instagram_account)
    @conversion_count = instagram_user.conversions.count
    @instagram_message_count = instagram_user.chatbot_usages.count
  end

  def create
    instagram_user = InstagramUser.find_by(id: params[:instagram_user_id])
    return render json: {code: 2, message: "Not found"} if instagram_user.blank?
    message_bag = MessageBag.find_by(id: params[:message_bag_id])
    return render json: {code: 2, message: "Not found"} if message_bag.blank?
    conversion = Conversion.new(instagram_user: instagram_user,
                      user_name: instagram_user.username,
                      user_source: instagram_user.start_chatbot_in,
                      conversion_at: Time.current,
                      message_bag_id: message_bag.id)
    return render json: {code: 1, message: "Success"} if conversion.save
    render json: {code: 2, data: conversion.errors.full_messages}
  end

  private

  def parse_date_range
    return [nil, nil] if params[:begin_date].blank? || params[:end_date].blank?

    [params[:begin_date].to_date, params[:end_date].to_date]
  end

  def filter_users_by_created_at(scope, begin_date, end_date)
    return scope if begin_date.blank? || end_date.blank?

    scope.where(created_at: begin_date.beginning_of_day..end_date.end_of_day)
  end

  def build_channel_stats(instagram_users, begin_date, end_date)
    CHANNELS.each_with_object({}) do |(key, channel_scope), stats|
      channel_users = instagram_users.public_send(channel_scope)
      user_ids = channel_users.pluck(:id)

      message_scope = ChatbotUsage.where(instagram_user_id: user_ids)
      conversion_scope = Conversion.where(instagram_user_id: user_ids)

      if begin_date.present? && end_date.present?
        message_scope = message_scope.search_by_begin_date_and_end_date(begin_date, end_date)
        conversion_scope = conversion_scope.search_by_begin_date_and_end_date(begin_date, end_date)
      end

      stats[key] = {
        user_count: channel_users.count,
        message_count: message_scope.count,
        conversion_count: conversion_scope.count
      }
    end
  end
end

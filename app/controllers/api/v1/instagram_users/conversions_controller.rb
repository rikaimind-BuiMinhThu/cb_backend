class Api::V1::InstagramUsers::ConversionsController < ApplicationController
  skip_before_action :permision, only: [:create]
  skip_before_action :verify_authenticity_token

  def index
    instagram_users = InstagramUser.all
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || current_user.admin_client?
    instagram_users = instagram_users.where(instagram_account: current_user.instagram_account)
    live_instagram_users = instagram_users.live_comment
    story_instagram_users = instagram_users.story_comment
    dm_instagram_users = instagram_users.dm

    @live_instagram_user_count = live_instagram_users.count
    @story_instagram_user_count = story_instagram_users.count
    @dm_instagram_user_count = dm_instagram_users.count

    @live_instagram_message_count = ChatbotUsage.where(instagram_user: live_instagram_users.pluck(:id)).count
    @story_instagram_message_count = ChatbotUsage.where(instagram_user: story_instagram_users.pluck(:id)).count
    @dm_instagram_message_count = ChatbotUsage.where(instagram_user: dm_instagram_users.pluck(:id)).count

    @live_conversion_count = Conversion.where(instagram_user: live_instagram_users.pluck(:id)).count
    @story_conversion_count = Conversion.where(instagram_user: story_instagram_users.pluck(:id)).count
    @dm_conversion_count = Conversion.where(instagram_user: dm_instagram_users.pluck(:id)).count
  end

  def show
    instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if instagram_user.blank?
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && instagram_user.instagram_account == current_user.instagram_account)
    @conversion_count = instagram_user.conversions.count
    @instagram_message_count = instagram_user.chatbot_usage.count
  end

  def create
    instagram_user = InstagramUser.find_by(id: params[:instagram_user_id])
    return render json: {code: 2, data: "Not found"} if instagram_user.blank?
    message_bag = MessageBag.find_by(id: params[:instagram_user_id])
    return render json: {code: 2, data: "Not found"} if message_bag.blank?
    conversion = Conversion.new(instagram_user: instagram_user,
                      user_name: instagram_user.username,
                      user_source: instagram_user.start_chatbot_in,
                      conversion_at: Time.current,
                      message_bag_id: message_bag.id)
    return render json: {code: 1, data: "success"} if conversion.save
    render json: {code: 2, data: conversion.errors.full_messages}
  end
end

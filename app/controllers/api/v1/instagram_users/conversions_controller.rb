class Api::V1::InstagramUsers::ConversionsController < ApplicationController
  skip_before_action :permision, only: [:create]
  skip_before_action :verify_authenticity_token

  def show
    instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, data: "Not found"} if instagram_user.blank?
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && instagram_user.instagram_account == current_user.instagram_account)
    @conversions = instagram_user.conversions
  end

  def create
    instagram_user = InstagramUser.find_by(id: params[:instagram_user_id])
    return render json: {code: 2, data: "Not found"} if instagram_user.blank?
    conversion = Conversion.new(instagram_user: instagram_user,
                      user_name: instagram_user.username,
                      user_source: instagram_user.start_chatbot_in,
                      conversion_at: Time.current,
                      message_bag_id: params[:message_bag_id])
    return render json: {code: 1, data: "success"} if conversion.save
    render json: {code: 2, data: conversion.errors.full_messages}
  end
end

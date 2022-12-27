class Api::V1::InstagramSettingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @instagram_accounts = InstagramAccount.where(user_id: current_user.id)
                                          .includes(:post_comment_bag, :story_comment_bag, :live_comment_bag)
    # render json: {code: 1, data: instagram_accounts}
  end

  def show
    instagram_account = InstagramAccount.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find instagram setting"} if instagram_account.blank?
    return render json: {code: 2, message: "User can't permission"} if instagram_account.user_id != current_user.id
    render json: {code: 1, data: instagram_account}
  end

  def update
    instagram_account = InstagramAccount.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find instagram account"} if instagram_account.blank?
    return render json: {code: 2, message: "User can't permission"} if instagram_account.user_id != current_user.id
    post_comment_bag = MessageBag.find_by(id: params[:instagram_setting][:post_comment_bag_id])
    story_comment_bag = MessageBag.find_by(id: params[:instagram_setting][:story_comment_bag_id])
    live_comment_bag = MessageBag.find_by(id: params[:instagram_setting][:live_comment_bag_id])
    default_reply_bag = MessageBag.find_by(id: params[:instagram_setting][:default_reply_bag_id])
    instagram_account.update post_comment_bag: post_comment_bag, story_comment_bag: story_comment_bag, live_comment_bag: live_comment_bag, default_reply_bag: default_reply_bag
    render json: {code: 1, data: instagram_account}
  end

  def change_status
    instagram_account = InstagramAccount.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find instagram account"} if instagram_account.blank?
    return render json: {code: 2, message: "User can't permission"} if instagram_account.user_id != current_user.id

    instagram_setting = params[:instagram_setting]

    return render json: {code: 2, message: "Invalid data"} \
      if instagram_setting[:post_comment_bag_status].present? && InstagramAccount.post_comment_bag_statuses.exclude?(instagram_setting[:post_comment_bag_status])
    return render json: {code: 2, message: "Invalid data"} \
      if instagram_setting[:story_comment_bag_status].present? && InstagramAccount.story_comment_bag_statuses.exclude?(instagram_setting[:story_comment_bag_status])
    return render json: {code: 2, message: "Invalid data"} \
      if instagram_setting[:live_comment_bag_status].present? && InstagramAccount.live_comment_bag_statuses.exclude?(instagram_setting[:live_comment_bag_status])

    instagram_account.post_comment_bag_status = instagram_setting[:post_comment_bag_status] unless instagram_setting[:post_comment_bag_status].nil?
    instagram_account.story_comment_bag_status = instagram_setting[:story_comment_bag_status] unless instagram_setting[:story_comment_bag_status].nil?
    instagram_account.live_comment_bag_status = instagram_setting[:live_comment_bag_status] unless instagram_setting[:live_comment_bag_status].nil?
    return render json: {code: 1, data: instagram_account} if instagram_account.save
    render json: {code: 2, message: "error"}
  end

  def connect
    result = FacebookManager::InstagramSetting.new(params[:fb_AuthResponse], params[:page_id], params[:ig_id], current_user.id).connect
    return render json: {code: 2, message: result.to_s} if result != 1
    render json: {code: 1, message: "Success!"}
  end

  def destroy
    instagram_account = InstagramAccount.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find instagram setting"} if instagram_account.blank?
    return render json: {code: 2, message: "User can't permission"} if instagram_account.user_id != current_user.id
    if instagram_account.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Fail!"}
    end
  end
end

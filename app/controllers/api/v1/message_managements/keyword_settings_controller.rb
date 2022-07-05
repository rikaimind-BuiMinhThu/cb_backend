class Api::V1::MessageManagements::KeywordSettingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    instagram_account_ids = InstagramAccount.where(user: current_user).pluck(:id)
    keywords = KeywordSetting.where(instagram_account_id: instagram_account_ids)
    render json: {code: 1, data: keywords}
  end

  def active
    instagram_account_ids = InstagramAccount.where(user: current_user).pluck(:id)
    keywords = KeywordSetting.where(instagram_account_id: instagram_account_ids).active
    render json: {code: 1, data: keyword}
  end

  def create
    instagram_account = InstagramAccount.find_by(id: params[:keyword_setting][:instagram_account_id])
    return render json: {code: 2, keyword: "Not have permission"} if instagram_account.blank? || instagram_account.user_id != current_user.id
    keyword = KeywordSetting.create keyword_params
    render json: {code: 1, keyword: keyword}
  end

  def show
    keyword = KeywordSetting.find_by(id: params[:id])
    return render json: {code: 2, keyword: "Cannot find keyword"} if keyword.blank?
    return render json: {code: 2, keyword: "Not have permission"} if keyword.instagram_account.user_id != current_user.id
    render json: {code: 1, data: keyword}
  end

  def update
    keyword = KeywordSetting.find_by(id: params[:id])
    return render json: {code: 2, keyword: "Cannot find keyword"} if keyword.blank?
    return render json: {code: 2, keyword: "Not have permission"} if keyword.instagram_account.user_id != current_user.id
    keyword.update keyword_params
    render json: {code: 1, data: keyword}
  end

  def destroy
    keyword = KeywordSetting.find_by(id: params[:id])
    return render json: {code: 2, keyword: "Cannot find keyword"} if keyword.blank?
    return render json: {code: 2, keyword: "Not have permission"} if keyword.instagram_account.user_id != current_user.id
    if keyword.destroy
      render json: {code: 1, keyword: "Success!"}
    else
      render json: {code: 2, keyword: "Something went wrong!"}
    end
  end

  private

  def keyword_params
    params.require(:keyword_setting).permit(:title, :keyword, :instagram_account_id, :is_dm, :is_story_comment, :is_post_comment, :is_live_comment, :message_bag_id, :is_active)
  end
end

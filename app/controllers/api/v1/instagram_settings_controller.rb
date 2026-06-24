class Api::V1::InstagramSettingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @instagram_accounts = InstagramAccount.where(user_id: current_user.id)
                                          .includes(:post_comment_bag, :story_comment_bag, :live_comment_bag, :default_reply_bag)
    # render json: {code: 1, data: instagram_accounts}
  end

  def profile
    instagram_account = current_user.instagram_account
    return render json: { code: 2, message: 'You need connect instagram account first' } if instagram_account.blank?
    return render json: { code: 2, message: 'Missing page access token' } if instagram_account.page_access_token.blank?

    result = FacebookManager::GraphApiClient.new(instagram_account.page_access_token).get(
      instagram_account.ig_id.to_s,
      fields: 'id,username,ig_id,name,profile_picture_url'
    )
    return render json: { code: 2, message: result.dig(:error, :message), meta_error: result[:error] } unless result[:success]

    render json: { code: 1, data: result[:data] }
  end

  def show
    instagram_account = InstagramAccount.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find instagram setting"} if instagram_account.blank?
    return render json: {code: 2, message: "User can't permission"} if instagram_account.user_id != current_user.id
    render json: {code: 1, data: instagram_account}
  end

  def logout_fb
    ig_account = InstagramAccount.find_by(ig_id: params[:ig_id], user_id: current_user.id)
    ig_account.update(page_access_token: nil) if ig_account
    return render json: {code: 2, message: "Cannot find instagram account"} if ig_account.blank?
    render json: {code: 1, message: "Logout success"}
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
    return render json: { code: 2, message: 'Unauthorized' }, status: 401 if current_user.blank?

    granted_scopes = extract_granted_scopes(params[:fb_AuthResponse])
    Rails.logger.info(
      "[instagram_connect] user_id=#{current_user.id} ig_id=#{params[:ig_id]} " \
      "page_id=#{params[:page_id]} grantedScopes=#{granted_scopes}"
    )

    result = FacebookManager::InstagramSetting.new(
      params[:fb_AuthResponse],
      params[:page_id],
      params[:ig_id],
      current_user.id,
      page_access_token: params[:page_access_token]
    ).connect

    if result != 1
      Rails.logger.warn("[instagram_connect] failed: #{result} grantedScopes=#{granted_scopes}")
      return render json: { code: 2, message: result.to_s, granted_scopes: granted_scopes }
    end

    render json: { code: 1, message: 'Success!', granted_scopes: granted_scopes }
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[instagram_connect] #{e.class}: #{e.message}")
    render json: { code: 2, message: "Database error: #{e.message}" }, status: 200
  rescue StandardError => e
    Rails.logger.error("[instagram_connect] #{e.class}: #{e.message}")
    render json: { code: 2, message: "Connect failed: #{e.message}" }, status: 200
  end

  def extract_granted_scopes(fb_auth_response)
    return nil if fb_auth_response.blank?

    raw = fb_auth_response.respond_to?(:to_unsafe_h) ? fb_auth_response.to_unsafe_h : fb_auth_response
    raw = raw.with_indifferent_access if raw.respond_to?(:with_indifferent_access)
    raw[:grantedScopes] || raw['grantedScopes']
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

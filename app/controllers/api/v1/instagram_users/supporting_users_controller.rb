class Api::V1::InstagramUsers::SupportingUsersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def destroy
    instagram_user = InstagramUser.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find instagram user"} if instagram_user.blank?
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && instagram_user.instagram_account == current_user.instagram_account)
    instagram_user.supporting_users.delete_all
    render json: {code: 1, data: "Success destroy"}
  end
end

class Api::V1::InstagramUsers::LabelsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    label = InstagramUserLabel.new(label_params)
    label.is_admin_add = true
    return render json: {code: 1, data: label} if label.save
    render json: {code: 2, message: "Something went wrong!"}
  end

  def show
    label = InstagramUserLabel.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find label"} if label.blank?
    render json: {code: 1, data: label}
  end

  def update
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    label = InstagramUserLabel.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find label"} if label.blank?
    if label.update label_params
      render json: {code: 1, data: label}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def destroy
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    label = InstagramUserLabel.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find label"} if label.blank?
    if label.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  private

  def label_params
    params.require(:label).permit(:name, :instagram_user_id)
  end
end

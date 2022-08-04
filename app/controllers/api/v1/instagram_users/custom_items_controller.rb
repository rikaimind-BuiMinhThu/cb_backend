class Api::V1::InstagramUsers::CustomItemsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    custom_item = CustomItem.new(custom_item_params)
    return render json: {code: 1, data: custom_item} if custom_item.save
    render json: {code: 2, message: "Something went wrong!"}
  end

  def show
    custom_item = CustomItem.find_by(id: params[:id])
    return render json: {code: 2, message: "Cannot find item"} if custom_item.blank?
    render json: {code: 1, data: custom_item}
  end

  def update
    custom_item = CustomItem.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find item"} if custom_item.blank?
    if custom_item.update custom_item_params
      render json: {code: 1, data: custom_item}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  def destroy
    custom_item = CustomItem.find_by(id: params[:id])
    return render json: {code: 2, data: "Cannot find item"} if custom_item.blank?
    if custom_item.destroy
      render json: {code: 1, message: "Success!"}
    else
      render json: {code: 2, message: "Something went wrong!"}
    end
  end

  private

  def custom_item_params
    params.require(:custom_item).permit(:title, :value, :instagram_user_id)
  end
end

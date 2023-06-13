class Api::V1::Managements::PlansController < ApplicationController

  def create
    return render json: {code: 2, message: "Function not available"} 
  end

  def index
    return render json: {code: 2, message: "No have permission"} unless current_user.admin_deel?
    render json: {code: 1, data: Plan.all}
  end

  def show
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel?
    plan = Plan.find_by(id: params[:id])
    return render json: {code: 1, data: plan} if plan.present?
    render json: {code: 2, message: "Not found"}
  end

  def update
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel?
    plan = Plan.find_by(id: params[:id])
    return render json: {code: 2, message: "Data not found"} if plan.blank?
    params[:plan][:description] = params[:plan][:description] if params[:plan][:description].present?
    params[:plan][:price] = params[:plan][:price] if params[:plan][:price].present?
    return render json: {code: 1, message: "Success"} if plan.update plan_params
    render json: {code: 2, message: "Fail"}
  end

  def destroy
    return render json: {code: 2, message: "Function not available"} 
  end

  private

  def plan_params
    params.require(:plan).permit(:description, :price)
  end
end

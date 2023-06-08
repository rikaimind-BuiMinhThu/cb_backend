class Api::V1::Managements::PlansController < ApplicationController

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    begin
      Plan.transaction do 
        max_code = Plan.maximum(:code)
        item = Plan.find_by(code: max_code)
        @plan = Plan.new(plan_params)
        @plan.code = item.code + 1
        if @plan.save!
          render json: {code: 1, message: "Success"}
        end
      end
      rescue Exception => e
        return render json: {code: 2, message: e}
    end
  end

  def index
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    k = params[:keyword]
    if k.present?
      if parse_price(k).present?
        @plans = Plan.ransack(price_eq: parse_price(k)).result
      else
        @plans = Plan.ransack(name_cont: params[:keyword]).result
      end
    else 
      @plans = Plan.all
    end
    @total = @plans.size
    @plans = @plans.page(params[:page]).per(20)
    render json: {code: 1, data: @plans, total: @total}
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
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    plan = Plan.find_by(id: params[:id])
    return render json: {code: 1, message: "Success"} if plan.destroy
    render json: {code: 2, message: "Fail"}
  end

  private

  def plan_params
    params.require(:plan).permit(:description, :price, :name)
  end

  def parse_price(keyword)
    # Kiểm tra xem keyword có phải là một số nguyên hay không
    if keyword.to_i.to_s == keyword
      keyword.to_i
    else
      nil
    end
  end
end

class Api::V1::Managements::SystemSettingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    return render json: { code: 2, message: "No permission" } unless current_user.admin_deel?

    render json: {
      code: 1,
      data: {
        lexica_max_chrome: SystemSetting.lexica_max_chrome
      }
    }
  end

  def update
    return render json: { code: 2, message: "No permission" } unless current_user.admin_deel?

    value = SystemSetting.lexica_max_chrome = params[:lexica_max_chrome]
    render json: { code: 1, data: { lexica_max_chrome: value } }
  end
end

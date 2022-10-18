class Api::V1::PrefecturesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    prefectures = Prefecture.select(:id, :name)
    render json: {code: 1, data: prefectures}
  end
end

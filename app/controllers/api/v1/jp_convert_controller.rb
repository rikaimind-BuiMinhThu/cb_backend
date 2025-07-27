class Api::V1::JpConvertController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def convert
    @hiragana = JpConvert.to_hiragana(safe_params[:text])
    @original_text = safe_params[:text]
  end

  def safe_params
    params.permit(:text)
  end
end
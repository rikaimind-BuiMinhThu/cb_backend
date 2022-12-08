class Api::V1::PrefecturesController < ApplicationController
  skip_before_action :permision
  skip_before_action :verify_authenticity_token

  def index
    prefectures = Prefecture.select(:id, :prefecture_jis_code, :name, :prefecture_name_kana)
    render json: {code: 1, data: prefectures}
  end

  def get_cities
    cities = City.select(:id, :prefecture_jis_code, :city_jis_code, :city_name, :city_name_kana)
                 .where(prefecture_jis_code: params[:prefecture_jis_code])
    render json: {code: 1, data: cities}
  end

  def get_towns
    towns = Town.select(:id, :prefecture_jis_code, :city_jis_code, :town_name, :town_name_kana, :zip_code)
                 .where(city_jis_code: params[:city_jis_code])
    render json: {code: 1, data: towns}
  end

  def get_address_from_zip_code
    @town = Town.select(:id, :town_name, :town_name_kana, :zip_code, :city_jis_code, :prefecture_jis_code)
               .find_by(zip_code: params[:zip_code])
  end
end

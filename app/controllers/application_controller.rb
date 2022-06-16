class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  require "jsonwebtoken"
  # respond_to :json, if: Proc.new {|c| c.request.format == "application/json"}

  before_action :permision

  def authenticate_request!
    token = request.headers['Authorization'].split(' ').last rescue nil
    payload = token.nil? ? nil : JsonWebToken.decode(token) rescue nil
    if payload.nil? || !JsonWebToken.valid_payload(payload.first)
      render json: {code: 0,
        message: "You need to sign in before continuing."}, status: 401
      return
    end
    @current_user = User.find_by_id payload.first["user_id"]
  end

  def permision
    authenticate_request!
  end

  def current_user
    @current_user
  end

  def load_user_authentication
    @user = User.find_by email: user_params[:email]
    unless (@user && @user.valid_password?(user_params[:password]))
      return render json: {code: 0,
        message: t("devise.failure.not_found_in_database")}, status: 200
    end
    # trackable
    @user.update_tracked_fields!(request)
  end
end

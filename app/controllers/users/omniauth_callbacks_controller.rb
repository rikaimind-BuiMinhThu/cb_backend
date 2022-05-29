class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :permision

  Devise.omniauth_providers.each do |provider|
    define_method provider do
      handle_with_omniauth
    end
  end

  def failure
    render json: {code: 2, data: failure_message}

  end

  private
  def handle_with_omniauth
    if identity = Identity.find_by(identity_hash)
      set_flash_message!(:notice, :signed_in)
      # sign_in_and_redirect identity.user and return
      return render json: {code: 1, data: identity.user}
    end

    if auth.info.email.nil?
      flash[:notice] = t "registration.not_email"
      return render json: {code: 2, data: "not have email"}
    end

    @user = User.from_omniauth auth
    @user.identities.create identity_hash
    sign_in_and_redirect @user
    render json: {code: 1, data: @user}
  end

  def auth
    @auth ||= request.env["omniauth.auth"]
  end

  def identity_hash
    {
      provider: auth.provider,
      uid: auth.uid
    }
  end

  def user_hash
    full_name = auth.info.name || auth.info.nickname

    {
      full_name: full_name,
      last_name: last_name,
      email: auth.info.email,
    }
  end
end

class Api::V1::Managements::ClientsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    if Client.find_by_name(client_params[:name])
      render json: {:code => 2, message: "Client name has unique."}
      return
    end
    begin
      Client.transaction do
        User.transaction do
          @client = Client.new(client_params)
          if @client.save!
            @user = User.new(email: client_params[:email],
                            password: user_params[:password],
                            password_confirmation: user_params[:password_confirmation],
                            role: 'admin_client', client_id: @client.id)
            @user.save!
          end
        end
      end
    rescue Exception => e
      return render json: {code: 2, message: e}
    end
  end

  def index
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    @conversion_begin_date = params[:conversion_begin_date].to_date rescue ''
    @conversion_end_date = params[:conversion_end_date].to_date rescue ''
    @clients = Client.ransack(name_or_address_cont: params[:name], plan_eq: params[:plan]).result
    @total = @clients.size
    @clients = @clients.select(:id, :logo_url, :name, :plan, :price, :subscription_start_at,
                               :subscription_end_at, :address, :prefecture, :building_name)
                       .order(created_at: :desc)
                       .page(params[:page])
    # render json: {code: 1, data: {clients: clients, total: total}}
  end

  def show
    client = Client.find_by(id: params[:id])
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && client.id == current_user.client_id)
    return render json: {code: 1, data: client} if client.present?
    render json: {code: 2, data: "Not found"}
  end

  def update
    client = Client.find_by(id: params[:id])
    return render json: {code: 2, data: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && client.id == current_user.client_id)
    return render json: {code: 2, data: "Data not found"} if client.blank?
    params[:client][:subscription_start_at] = params[:client][:subscription_start_at].to_time if params[:client][:subscription_start_at].present?
    params[:client][:subscription_end_at] = params[:client][:subscription_end_at].to_time if params[:client][:subscription_end_at].present?
    return render json: {code: 1, data: "Success"} if client.update client_params
    render json: {code: 2, data: "Fail"}
  end

  def destroy
    return render json: {code: 2, data: "No permission"} unless current_user.admin_deel?
    client = Client.find_by(id: params[:id])
    return render json: {code: 1, data: "Success"} if client.destroy
    render json: {code: 2, data: "Fail"}
  end

  private

  def client_params
    params.require(:client).permit(:name, :address, :phone_number, :status, :plan,
      :price, :subscription_start_at, :subscription_end_at, :is_instagram, :is_line,
      :is_tiktok, :is_web, :note, :enterprise_type, :enterprise_type_2, :department_name,
      :title, :responsible_person, :logo_url, :url, :zip_code, :prefecture,
      :municipality, :building_name, :email, :name_katakana, :responsible_person_katakana)
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end

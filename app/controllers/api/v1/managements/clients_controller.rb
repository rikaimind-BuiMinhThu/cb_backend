class Api::V1::Managements::ClientsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
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
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    @conversion_begin_date = params[:conversion_begin_date].to_date.beginning_of_day rescue ''
    @conversion_end_date = params[:conversion_end_date].to_date.end_of_day rescue ''
    @clients = Client.ransack(name_or_address_cont: params[:name], plan_eq: params[:plan]).result
    @total = @clients.size
    status_orders = [Client.statuses[:active], Client.statuses[:trial], Client.statuses[:pause], Client.statuses[:ended]]
    date_conditions = ""
    if @conversion_begin_date.present?
      date_conditions = "#{date_conditions} AND orders.created_at >= '#{@conversion_begin_date}'"
    end 
    if @conversion_end_date.present?
      date_conditions = "#{date_conditions} AND orders.created_at <= '#{@conversion_end_date}'"
    end
    @clients = @clients.select(:id, :logo_url, :name, :plan, :price, :subscription_start_at,
                               :subscription_end_at, :address, :prefecture, :building_name,
                               :status, :municipality, :is_instagram, :is_web, :is_line, :is_tiktok,
                               :unit_price_instagram, :unit_price_web, :unit_price_line, :unit_price_tiktok,
                              "(SELECT COUNT(*) FROM orders WHERE orders.client_id = clients.id AND orders.bot_type = 0 #{date_conditions}) AS bot_cv_instagram",
                              "(SELECT COUNT(*) FROM orders WHERE orders.client_id = clients.id AND orders.bot_type = 1 #{date_conditions}) AS bot_cv_web",
                              "(SELECT COUNT(*) FROM orders WHERE orders.client_id = clients.id AND orders.bot_type = 2 #{date_conditions}) AS bot_cv_line",
                              "(SELECT COUNT(*) FROM orders WHERE orders.client_id = clients.id AND orders.bot_type = 3 #{date_conditions}) AS bot_cv_tiktok",
                              )
                       .order(Arel.sql("field(status, #{status_orders.join(',')})"), created_at: :desc)
                       .page(params[:page])
    # render json: {code: 1, data: {clients: clients, total: total}}
  end

  def show
    client = Client.find_by(id: params[:id])
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && client.id == current_user.client_id)
    return render json: {code: 1, data: client} if client.present?
    render json: {code: 2, message: "Not found"}
  end

  def update
    client = Client.find_by(id: params[:id])
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel? || (current_user.admin_client? && client.id == current_user.client_id)
    return render json: {code: 2, message: "Data not found"} if client.blank?
    params[:client][:subscription_start_at] = params[:client][:subscription_start_at].to_time if params[:client][:subscription_start_at].present?
    params[:client][:subscription_end_at] = params[:client][:subscription_end_at].to_time if params[:client][:subscription_end_at].present?
    return render json: {code: 1, message: "Success"} if client.update client_params
    render json: {code: 2, message: "Fail"}
  end

  def destroy
    return render json: {code: 2, message: "No permission"} unless current_user.admin_deel?
    client = Client.find_by(id: params[:id])
    return render json: {code: 1, message: "Success"} if client.destroy
    render json: {code: 2, message: "Fail"}
  end

  def get_client_with_name
    return render json: {code: 2, message: "Not have permission"} unless current_user.admin_deel?
    clients = Client.select(:id, :name)
    render json: {code: 1, data: clients}
  end

  private

  def client_params
    params.require(:client).permit(:name, :address, :phone_number, :status, :plan,
      :price, :subscription_start_at, :subscription_end_at, :is_instagram, :is_line,
      :is_tiktok, :is_web, :note, :enterprise_type, :enterprise_type_2, :department_name,
      :title, :responsible_person, :logo_url, :url, :zip_code, :prefecture,
      :municipality, :building_name, :email, :name_katakana, :responsible_person_katakana,
      :unit_price_instagram, :unit_price_web, :unit_price_line, :unit_price_tiktok, :cart_system,
      :zettai_reach_bot_id, :zettai_reach_client_id, :shop_url, :client_id, :client_secret)
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end

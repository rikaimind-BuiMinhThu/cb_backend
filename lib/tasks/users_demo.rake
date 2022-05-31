namespace :users_demo do
  task run: :environment do
    puts 'create users demo ...'
    admin_deel = {
      full_name: "admin deel",
      email: "admin_deel@gmail.com",
      password: "12345678",
      role: "admin_deel"
    }
    create_user admin_deel
    admin_client = {
      full_name: "admin client",
      email: "admin_client@gmail.com",
      password: "12345678",
      role: "admin_client"
    }
    create_user admin_client
    user_client = {
      full_name: "client demo",
      email: "client@gmail.com",
      password: "12345678",
      role: "client"
    }
    create_user user_client
    client_1 = {
      name: "Client 1",
      address: "Rikai 1 HN",
      phone_number: "0981312412"
    }
    create_client client_1
    client_2 = {
      name: "Client 2",
      address: "Rikai 2 HN",
      phone_number: "0981234152"
    }
    create_client client_2
    user_client_1 = {
      full_name: "user 1 demo",
      email: "user1@gmail.com",
      password: "12345678",
      role: "client",
      client_id: 1
    }
    create_user user_client_1
    user_client_2 = {
      full_name: "user 2 demo",
      email: "user2@gmail.com",
      password: "12345678",
      role: "client",
      client_id: 2
    }
    create_user user_client_2
    puts 'done'
  end

  def create_user user_params
    if User.find_by_email(user_params[:email])
      return
    end
    user = User.create user_params
  end

  def create_client client_params
    if Client.find_by_name(client_params[:name])
      return
    end
    user = Client.create client_params
  end
end

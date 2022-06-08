namespace :users_demo do
  task run: :environment do
    puts 'create users demo ...'

    clients = []
    (1..10).each do |i|
      clients.push({
        name: "Client #{i}",
        address: "Rikai #{i} HN",
        phone_number: "098131241#{i}"
      })
    end
    clients.each {|client| Client.create(client)}

    users = []

    users.push({
      full_name: "admin deel",
      email: "admin_deel@gmail.com",
      password: "12345678",
      role: "admin_deel"
    })

    (1..10).each do |i|

      users.push({
        full_name: "admin client #{i}",
        email: "admin_client_#{i}@gmail.com",
        password: "12345678",
        role: "admin_client",
        client_id: i
      })
    end

    (1..100).each do |i|
      users.push({
        full_name: "client #{i}",
        email: "client_#{i}@gmail.com",
        password: "12345678",
        role: "client",
        client_id: i%10 + 1
      })
    end
    users.each do |user|
      u = User.new(user)
      u.save(validate: false)
    end

    puts 'done'
  end
end

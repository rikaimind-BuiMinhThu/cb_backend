namespace :delete_supporting_user do
  task run: :environment do
    SupportingUser.delete_all
  end
end

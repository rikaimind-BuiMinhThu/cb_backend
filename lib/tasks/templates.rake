# frozen_string_literal: true

namespace :templates do
  desc "Upsert scenario + order-confirm templates from db/seeds/templates.rb"
  task seed: :environment do
    load Rails.root.join("db/seeds/templates.rb")
  end
end

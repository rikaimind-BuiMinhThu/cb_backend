class UpdatePlans < ActiveRecord::Migration[7.0]
  def up
    Plan.create(name: "スタートアップ", code: 0, price: 0)
    Plan.create(name: "プレミアム", code: 1, price: 0)
    Plan.create(name: "エキスパート", code: 2, price: 0)
    Plan.create(name: "完全成果報酬", code: 4, price: 0)
  end

  def down
    Plan.destroy_all
  end
end

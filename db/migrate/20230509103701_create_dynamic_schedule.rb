class CreateDynamicSchedule < ActiveRecord::Migration[7.0]
  def change
    create_table :dynamic_schedules do |t|
      t.string :name
      t.string :args
      t.string :class_name
      t.string :priority
      t.string :cron

      t.integer :status
      t.string :job_type
      t.integer :reference_id
      

      t.timestamps
    end
  end
end

class AddInstagramAccountToIceBreakersAndPersistentMenus < ActiveRecord::Migration[7.0]
  def change
    add_reference :ice_breakers, :instagram_account, null: false, foreign_key: true
    add_reference :persistent_menus, :instagram_account, null: false, foreign_key: true
  end
end

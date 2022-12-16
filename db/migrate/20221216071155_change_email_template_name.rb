class ChangeEmailTemplateName < ActiveRecord::Migration[7.0]
  def change
    change_column :emails, :email_template_name, :text
  end
end

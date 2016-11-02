class CreateLeads < ActiveRecord::Migration
  def change
    create_table :leads do |t|
      t.string :first_name
      t.string :company_name
      t.string :email_address
    end
  end
end

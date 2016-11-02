class AddExtraFieldsToLeads < ActiveRecord::Migration
  def change
    enable_extension "hstore"
    add_column :leads, :extended, :hstore
    add_index :leads, :extended, using: :gin
  end
end

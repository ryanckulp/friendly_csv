class AddTimestampsToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :created_at, :datetime
    add_column :batches, :updated_at, :datetime
  end
end

class AddDuplicateCountToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :duplicate_count, :integer
  end
end

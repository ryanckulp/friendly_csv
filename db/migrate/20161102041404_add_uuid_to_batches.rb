class AddUuidToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :uuid, :text
  end
end

class AddErrorsAndLeadsCountsToBatches < ActiveRecord::Migration
  def change
    add_column :batches, :errors, :integer
    add_column :batches, :lead_count, :integer
  end
end

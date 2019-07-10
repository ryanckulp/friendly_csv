class AddNotNullConstraintToBatches < ActiveRecord::Migration
  def change
    change_column_null :batches, :created_at, false
    change_column_null :batches, :updated_at, false
  end
end

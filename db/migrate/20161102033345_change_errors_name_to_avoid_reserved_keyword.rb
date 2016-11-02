class ChangeErrorsNameToAvoidReservedKeyword < ActiveRecord::Migration
  def change
    rename_column :batches, :errors, :error_count
  end
end

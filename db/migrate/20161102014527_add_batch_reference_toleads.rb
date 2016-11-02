class AddBatchReferenceToleads < ActiveRecord::Migration
  def change
    add_reference :leads, :batch, index: true
  end
end

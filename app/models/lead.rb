class Lead < ActiveRecord::Base
  belongs_to :batch

  def self.import(file, batch_id)
    ImportLeadsJob.perform_async(file, batch_id)
  end

  def self.to_csv(options = {})
      delete_list = ['id', 'created_at', 'updated_at', 'batch_id', 'extended']
      new_columns = column_names - delete_list

      CSV.generate(options) do |csv|
        lead = all.first
        csv << new_columns + lead.extended.keys

        all.each do |lead|
          extended_values = lead.extended.keys
          csv << lead.attributes.values_at(*new_columns) + lead.extended.values_at(*extended_values)
        end
      end
    end

end

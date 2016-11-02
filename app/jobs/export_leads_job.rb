class ExportLeadsJob
  include SuckerPunch::Job

  # could ask for user email, and send to them this way
  def perform(batch_id)
    batch = Export.find(batch_id)
    leads = batch.leads
    csv = leads.to_csv

    ExportMailer.send_leads(csv, batch.recipient_email).deliver_now
  end

end

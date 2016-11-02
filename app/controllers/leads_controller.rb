class LeadsController < ApplicationController

  def import
    batch = Batch.find(params[:batch_id])

    # store intended leads count being uploaded, for progress bar on :show
    lead_count = CSV.read(params[:file].path, headers: true, encoding:'iso-8859-1:utf-8', skip_blanks: true, skip_lines: /^(?:,\s*)+$/).count
    batch.update(lead_count: lead_count)

    Lead.import(params[:file], batch.id)
    # redirect_to batch_path(batch.uuid)
    redirect_to batch_preview_path(batch.uuid)
  end

end

class BatchesController < ApplicationController
  before_action :set_batch, only: [:edit, :show, :preview, :progress]

  def new
    @batch = Batch.create!
    redirect_to edit_batch_path(@batch.uuid)
  end

  def edit
  end

  def show
    @batch_uuid = @batch.uuid
    @leads = @batch.leads[0..15]
    @lead_count = @batch.lead_count
    @duplicate_count = @batch.duplicate_count
    @error_count = @batch.error_count
    @extended_attributes = @leads.try(:first).try(:extended).try(:keys) || []

    respond_to do |format|
      format.html
      format.csv { send_data @batch.leads.to_csv, filename: "leads-#{Date.today}.csv" }
    end
  end

  def preview
    @uuid = @batch.uuid
    @lead_count = @batch.lead_count
  end

  def progress
    completed = @batch.leads.count
    render json: {status: 'ok', completed: completed}
  end

  def create
    @batch = Batch.new(batch_params)

    respond_to do |format|
      if @batch.save
        format.html { redirect_to edit_batch_path(@batch.uuid) }
        format.json { render :show, status: :created, location: @batch }
      else
        format.html { render :new }
        format.json { render json: @batch.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_batch
      @batch = Batch.find_by(uuid: params[:id])
      return unless @batch.uuid.length == 32

      # wrong uuid, hacker, primary key attempt, etc
      rescue
      redirect_to root_path
    end

    def batch_params
      params.fetch(:batch, {})
    end

end

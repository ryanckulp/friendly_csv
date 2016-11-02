class PagesController < ApplicationController
  def home
    @batch = Batch.new
  end
end

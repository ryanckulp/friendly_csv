class Batch < ActiveRecord::Base
  has_many :leads, dependent: :destroy

  before_create :generate_uuid
  def generate_uuid
    until self.uuid.present?
      random_id = SecureRandom.hex(16)
      batch = Batch.find_by(uuid: random_id) # guarantee no overlap
      self.uuid = random_id if batch.nil?
    end
  end
end

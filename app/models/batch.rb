class Batch < ActiveRecord::Base
  has_many :leads, dependent: :destroy

  before_create :generate_uuid

  def generate_uuid
    self.uuid = loop do
      random_uuid = SecureRandom.hex(16)
      break random_uuid unless self.class.exists?(uuid: random_uuid)
    end
  end
end

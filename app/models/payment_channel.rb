class PaymentChannel < ApplicationRecord

  belongs_to :key

  before_create :generate_channel_id

  scope :channel_id, -> (channel_id) {where(channel_id: channel_id)}

  private
  def generate_channel_id
    self.channel_id = SecureRandom.uuid
  end

end

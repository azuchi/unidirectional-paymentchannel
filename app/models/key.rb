class Key < ApplicationRecord

  before_create :setup_key
  has_one :payment_channel

  private
  def setup_key
    key = Bitcoin::Key.generate
    self.pubkey = key.pub
    self.privkey = key.priv
  end

end

class Key < ApplicationRecord
  include Concerns::BitcoinWrapper

  before_create :setup_key
  has_one :payment_channel

  def to_btc_key
    key = Bitcoin::Key.new
    key.priv = privkey
    key
  end

  def to_addr
    pubkey_to_address(pubkey)
  end

  private
  def setup_key
    key = Bitcoin::Key.generate
    self.pubkey = key.pub
    self.privkey = key.priv
  end

end

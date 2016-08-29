class Key < ApplicationRecord

  before_create :setup_key

  private
  def setup_key
    key = Bitcoin::Key.generate
    self.pubkey = key.pub
    self.privkey = key.priv
  end

end

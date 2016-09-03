class PaymentChannel < ApplicationRecord

  belongs_to :key

  before_create :generate_channel_id

  scope :channel_id, -> (channel_id) {where(channel_id: channel_id)}

  # 払い戻し用トランザクションに署名
  def sign_to_refund_tx(refund_tx, redeem_script)
    sig_hash = refund_tx.signature_hash_for_input(0, redeem_script)
    script_sig = Bitcoin::Script.to_p2sh_multisig_script_sig(redeem_script)
    script_sig = Bitcoin::Script.add_sig_to_multisig_script_sig(key.to_btc_key.sign(sig_hash), script_sig)
    refund_tx.inputs[0].script_sig = script_sig
    refund_tx
  end

  private
  def generate_channel_id
    self.channel_id = SecureRandom.uuid
  end

end

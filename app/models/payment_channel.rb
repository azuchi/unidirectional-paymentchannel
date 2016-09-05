class PaymentChannel < ApplicationRecord
  include Concerns::BitcoinWrapper

  belongs_to :key

  before_create :generate_channel_id

  scope :channel_id, -> (channel_id) {where(channel_id: channel_id)}

  # 払い戻し用トランザクションに署名
  def sign_to_refund_tx(refund_tx, redeem_script)
    return false unless validate_refund_tx(refund_tx)
    sig_hash = refund_tx.signature_hash_for_input(0, redeem_script)
    script_sig = Bitcoin::Script.to_p2sh_multisig_script_sig(redeem_script)
    script_sig = Bitcoin::Script.add_sig_to_multisig_script_sig(key.to_btc_key.sign(sig_hash), script_sig)
    refund_tx.inputs[0].script_sig = script_sig
    self.refund_tx = refund_tx.to_payload.bth
    puts "model refund = #{refund_tx.to_payload.bth}"
    self.redeem_script = redeem_script.bth
    save
  end

  # OpeningTxをブロードキャストしチャンネルをオープンする
  def open(opening_tx)
    return false unless validate_opening_tx(opening_tx)
    self.opening_txid = opening_tx.hash
    broadcast_tx(opening_tx.to_payload.bth)
    save
  end

  # 最新のCommitment Transactionに更新する
  def update_commit_tx(tx)
    return false unless validate_commitment_tx(tx)
    self.commitment_tx = tx.to_payload.bth
    save
  end

  # 署名した払い戻し用トランザクションを取得
  def signed_refund_tx
    Bitcoin::Protocol::Tx.new(refund_tx.htb) if refund_tx
  end

  # Channelをクローズする
  def close
    self.close_txid =broadcast_tx(commitment_tx)
    save
  end

  private
  def generate_channel_id
    self.channel_id = SecureRandom.uuid
  end

  # 払い戻し用トランザクションにロックタイムがセットされているか検証
  def validate_refund_tx(refund_tx)
    if refund_tx.is_final?(current_block_height, current_block_time)
      errors[:base] << 'refund tx is already final.'
      return false
    end
    true
  end

  # Opening TxがこのChannelの払い戻し用トランザクションの入力か検証
  def validate_opening_tx(opening_tx)
    if signed_refund_tx.in[0].previous_output != opening_tx.hash
      errors[:base] << 'opening tx does not correspond to refund tx.'
      return false
    end
    true
  end

  # Commitment txの検証
  def validate_commitment_tx(tx)
    puts "opening_tx = #{tx.in[0].previous_output}"
    if tx.in[0].previous_output != opening_txid # 更新対象のTxが別のOpening Tx参照している場合はエラー
      errors[:base] << 'commitment tx does not correspond to opening tx.'
      return false
    end
    current_servers_value = commitment_tx.nil? ? 0 : servers_value(Bitcoin::Protocol::Tx.new(commitment_tx.htb))
    next_servers_value = servers_value(tx)
    if current_servers_value > next_servers_value # 更新対象のTxのサーバへのBTC量が前回より少なければエラー
      errors[:base] << 'commitment tx output has not enough bitcoin. '
      return false
    end
    # 署名の検証
    sig_hash = tx.signature_hash_for_input(0, redeem_script.htb)
    script_sig = tx.in[0].script_sig
    script_sig = Bitcoin::Script.add_sig_to_multisig_script_sig(key.to_btc_key.sign(sig_hash), script_sig)
    script_sig = Bitcoin::Script.sort_p2sh_multisig_signatures(script_sig, sig_hash)
    tx.in[0].script_sig = script_sig
    unless tx.verify_input_signature(0, Bitcoin::Protocol::Tx.new(raw_transaction(opening_txid).htb))
      errors[:base] << 'commitment tx signature is invalid.'
      return false
    end
    true
  end

  # tx内のサーバ向けの出力のBitcoin量を取得
  def servers_value(tx)
    return 0 unless tx
    out = tx.out.find{|o|
      addr = o.parsed_script.get_address
      server_addr = key.to_addr
      addr == server_addr
    }
    out ? out.value : 0
  end

end

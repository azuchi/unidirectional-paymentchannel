class PaymentChannel::Client

  include Concerns::BitcoinWrapper

  attr_reader :endpoint, :config
  attr_accessor :channel_id, :server_pubkey, :client_key

  def initialize(config: nil, endpoint: 'http://localhost:3000/payment_channels', client_key: Bitcoin::Key.generate)
    @endpoint = endpoint
    config = oa_config unless config
    @config = config
    @client_key = client_key
  end

  # サーバとChannelを開く
  def open
    RestClient.get("#{endpoint}/new", {}) do |respdata, request, result|
      self.channel_id = JSON.parse(respdata)['channel_id']
    end
  end

  # サーバに公開鍵を要求
  def request_new_pubkey
    RestClient.post("#{channel_url}/new_key", {}) do |respdata, request, result|
      self.server_pubkey = JSON.parse(respdata)['pubkey']
    end
  end

  # create opening transaction（とりあえず原資となるBTCは送られているものとする）
  def create_opening_tx(amount)
    p2sh_script, redeem_script =  Bitcoin::Script.to_p2sh_multisig_script(2, server_pubkey, client_key.pub)
    multisig_addr = Bitcoin::Script.new(p2sh_script).get_p2sh_address
    tx = oa_api.send_bitcoin(client_key.addr, amount, multisig_addr, 0, 'signed') # regtestなので手数料は考えない
    [tx, redeem_script]
  end

  # 払い戻し用トランザクションの作成
  def create_refund_tx(txid, vout, amount)
    tx = Bitcoin::Protocol::Tx.new
    tx.add_in(Bitcoin::Protocol::TxIn.from_hex_hash(txid, vout))
    tx.add_out(Bitcoin::Protocol::TxOut.value_to_address(amount, client_key.addr))
    tx
  end

  # 払い戻し用トランザクションの作成をサーバに依頼
  def request_sign_refund_tx(refund_tx, redeem_script)
    json = {tx: refund_tx.to_payload.bth, redeem_script: redeem_script.bth}.to_json
    RestClient.post("#{channel_url}/sign_refund_tx", json) do |respdata, request, result|
      Bitcoin::Protocol::Tx.new(JSON.parse(respdata)['tx'].htb)
    end
  end

  # サーバ側で署名された払い戻し用トランザクションの署名を検証
  def verify_half_signed_refund_tx(opening_tx, refund_tx, redeem_script)
    # サーバ側で署名されたデータに自分の署名を追加
    sig_hash = refund_tx.signature_hash_for_input(0, redeem_script)
    script_sig = refund_tx.inputs[0].script_sig
    script_sig = Bitcoin::Script.add_sig_to_multisig_script_sig(client_key.sign(sig_hash), script_sig)
    script_sig = Bitcoin::Script.sort_p2sh_multisig_signatures(script_sig, sig_hash)
    refund_tx.inputs[0].script_sig = script_sig
    # 署名の検証（Opening Txはまだブロードキャストされておらず手元にある）
    refund_tx.verify_input_signature(0, opening_tx)
  end

  # request server to sign and broadcast singed transaction
  def send_opening_tx(opening_tx)

  end

  # create commitment transaction and send it to server
  def create_commitment_tx(opening_tx, client_btc)

  end

  private
  def btc_config
    @config
  end

  def channel_url
    "#{endpoint}/#{channel_id}"
  end

end
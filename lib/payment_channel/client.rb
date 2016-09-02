class PaymentChannel::Client

  include Concerns::BitcoinWrapper

  attr_reader :endpoint, :config
  attr_accessor :channel_id, :server_pubkey, :client_key, :op_tx_redeem

  def initialize(config: nil, endpoint: 'http://localhost:3000/payment_channels', client_key: Bitcoin::Key.generate)
    @endpoint = endpoint
    config = oa_config unless config
    @config = config
    @client_key = client_key
  end

  # open the payment channel
  def open
    RestClient.get("#{endpoint}/new", {}) do |respdata, request, result|
      self.channel_id = JSON.parse(respdata)['channel_id']
    end
  end

  # request server public key
  def request_new_pubkey
    RestClient.post("#{channel_url}/new_key", {}) do |respdata, request, result|
      self.server_pubkey = JSON.parse(respdata)['pubkey']
    end
  end

  # create opening transaction（とりあえず原資となるBTCは送られているものとする）
  def create_opening_tx(amount)
    p2sh_script, redeem_script =  Bitcoin::Script.to_p2sh_multisig_script(2, server_pubkey, client_key.pub)
    self.op_tx_redeem = redeem_script
    multisig_addr = Bitcoin::Script.new(p2sh_script).get_p2sh_address
    tx = oa_api.send_bitcoin(client_key.addr, amount, multisig_addr, 0, 'signed') # regtestなので手数料は考えない
    tx
  end

  # create refund tx
  def create_refund_tx(txid, vout, amount)
    tx = Bitcoin::Protocol::Tx.new
    tx.add_in(Bitcoin::Protocol::TxIn.from_hex_hash(txid, vout))
    tx.add_out(Bitcoin::Protocol::TxOut.value_to_address(amount, client_key.addr))
    tx
  end

  # request server to sign refund transaction
  def request_sign_refund_tx(refund_tx)
    RestClient.post("#{endpoint}/new_key", {}) do |respdata, request, result|
      response = JSON.parse(respdata)
      self.server_pubkey = response['pubkey']
    end
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
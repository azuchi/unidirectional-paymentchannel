module Concerns::BitcoinWrapper

  extend ActiveSupport::Concern

  def btc_config
    YAML.load_file("#{Rails.root}/config/bitcoin.yml").deep_symbolize_keys
  end

  def btc_provider
    @btc_provider ||= BitcoinProvider.new(btc_config)
  end

  class BitcoinProvider

    attr_reader :config

    RPC_API = [
        :addmultisigaddress, :addnode, :backupwallet, :createmultisig, :createrawtransaction, :decoderawtransaction,
        :decodescript, :dumpprivkey, :dumpwallet, :encryptwallet, :estimatefee, :estimatepriority, :generate,
        :getaccountaddress, :getaccount, :getaddednodeinfo, :getaddressesbyaccount, :getbalance, :getbestblockhash,
        :getblock, :getblockchaininfo, :getblockcount, :getblockhash, :getchaintips, :getconnectioncount, :getdifficulty,
        :getgenerate, :gethashespersec, :getinfo, :getmempoolinfo, :getmininginfo, :getnettotals, :getnetworkhashps,
        :getnetworkinfo, :getnewaddress, :getpeerinfo, :getrawchangeaddress, :getrawmempool, :getrawtransaction,
        :getreceivedbyaccount, :getreceivedbyaddress, :gettransaction, :gettxout, :gettxoutproof, :gettxoutsetinfo,
        :getunconfirmedbalance, :getwalletinfo, :getwork, :help, :importaddress, :importprivkey, :importwallet,
        :keypoolrefill, :listaccounts, :listaddressgroupings, :listlockunspent, :listreceivedbyaccount, :listreceivedbyaddress,
        :listsinceblock, :listtransactions, :listunspent, :lockunspent, :move, :ping, :prioritisetransaction, :sendfrom,
        :sendmany, :sendrawtransaction, :sendtoaddress, :setaccount, :setgenerate, :settxfee, :signmessage, :signrawtransaction,
        :stop, :submitblock, :validateaddress, :verifychain, :verifymessage, :verifytxoutproof, :walletlock, :walletpassphrase,
        :walletpassphrasechange
    ]

    def initialize(config)
      @config = config
    end

    private
    def request(command, *params)
      data = {
          :method => command,
          :params => params,
          :id => 'jsonrpc'
      }
      post(server_url, 60, 60, data.to_json, content_type: :json) do |respdata, request, result|
        response = JSON.parse(respdata.gsub(/\\u([\da-fA-F]{4})/) { [$1].pack('H*').unpack('n*').pack('U*').encode('ISO-8859-1').force_encoding('UTF-8') })
        raise ApiError, response['error'] if response['error']
        response['result']
      end
    end

    def post(url, timeout, open_timeout, payload, headers={}, &block)
      RestClient::Request.execute(:method => :post, :url => url, :timeout => timeout, :open_timeout => open_timeout, :payload => payload, :headers => headers, &block)
    end

    def server_url
      rpc = config[:bitcoin][:rpc]
      url = "#{rpc[:schema]}://"
      url.concat "#{rpc[:user]}:#{rpc[:password]}@"
      url.concat "#{rpc[:host]}:#{rpc[:port]}"
      url
    end

    def method_missing(method, *params)
      super unless RPC_API.include?(method)
      request(method, *params)
    end
  end

end
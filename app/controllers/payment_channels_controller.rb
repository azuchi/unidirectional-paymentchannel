class PaymentChannelsController < ApplicationController

  include Concerns::BitcoinWrapper

  before_action :load_channel, except: [:new]

  # クライアントとのChannelを新規作成
  def new
    channel = PaymentChannel.new
    render json: {channel_id: channel.channel_id} if channel.save
  end

  # クライアントからの要求に答えて新しい公開鍵を作成
  def new_key
    @payment_channel.key = Key.new
    render json: {pubkey: @payment_channel.key.pubkey} if @payment_channel.save
  end

  # 払い戻し用のトランザクションに署名
  def sign_refund_tx
    payload = jparams[:tx]
    redeem_script = jparams[:redeem_script].htb
    tx = @payment_channel.sign_to_refund_tx(Bitcoin::Protocol::Tx.new(payload.htb), redeem_script)
    render json: {tx: tx.to_payload.bth}
  end

  private
  def load_channel
    @payment_channel = PaymentChannel.channel_id(params[:id]).first
  end

  def jparams
    @jparams ||= JSON.parse(request.body.read, {:symbolize_names => true})
  end

end
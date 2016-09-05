class PaymentChannelsController < ApplicationController

  include Concerns::BitcoinWrapper

  before_action :load_channel, except: [:new]

  # クライアントとのChannelを新規作成
  def new
    channel = PaymentChannel.new
    channel.key = Key.new
    if channel.save
      render json: {channel_id: channel.channel_id}
    else
      render json: {errors: channel.errors.full_messages}, status: 500
    end
  end

  # クライアントからの要求に答えて新しい公開鍵を作成
  def new_key
    render json: {pubkey: @payment_channel.key.pubkey}
  end

  # 払い戻し用のトランザクションに署名
  def sign_refund_tx
    payload = jparams[:tx]
    redeem_script = jparams[:redeem_script].htb
    if @payment_channel.sign_to_refund_tx(Bitcoin::Protocol::Tx.new(payload.htb), redeem_script)
      puts "controller refund = #{@payment_channel.refund_tx}"
      render json: {tx: @payment_channel.refund_tx}
    else
      render json: {errors: @payment_channel.errors.full_messages}, status: 500
    end
  end

  # OpeningTxを受け取りブロードキャストする
  def opening_tx
    payload = jparams[:tx]
    if @payment_channel.open(Bitcoin::Protocol::Tx.new(payload.htb))
      render json: {txid: @payment_channel.opening_txid}
    else
      render json: {errors: @payment_channel.errors.full_messages}, status: 500
    end
  end

  # Commitment Transactionを更新
  def commitment_tx
    payload = jparams[:tx]
    if @payment_channel.update_commit_tx(Bitcoin::Protocol::Tx.new(payload.htb))
      render json: {txid: Bitcoin::Protocol::Tx.new(@payment_channel.commitment_tx.htb).hash}
    else
      render json: {errors: @payment_channel.errors.full_messages}, status: 500
    end
  end

  private
  def load_channel
    @payment_channel = PaymentChannel.channel_id(params[:id]).first
  end

  def jparams
    @jparams ||= JSON.parse(request.body.read, {:symbolize_names => true})
  end

end
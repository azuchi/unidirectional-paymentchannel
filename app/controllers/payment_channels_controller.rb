class PaymentChannelsController < ApplicationController

  include Concerns::BitcoinWrapper

  before_action :load_channel, except: [:new]

  def new
    channel = PaymentChannel.new
    render json: {channel_id: channel.channel_id} if channel.save
  end

  # generate new public key
  def new_key
    @payment_channel.key = Key.new
    render json: {pubkey: @payment_channel.key.pubkey} if @payment_channel.save
  end

  private
  def load_channel
    @payment_channel = PaymentChannel.channel_id(params[:id]).first
  end

end
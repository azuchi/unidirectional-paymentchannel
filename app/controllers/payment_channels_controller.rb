class PaymentChannelsController < ApplicationController

  include Concerns::BitcoinWrapper

  # generate new public key
  def new_key
    key = Key.new
    render json: {pubkey: key.pubkey} if key.save
  end

end
require 'openassets'

module Concerns::BitcoinWrapper

  include Bitcoin::Util

  extend ActiveSupport::Concern

  def oa_api
    OpenAssets::Api.new(oa_config[:bitcoin])
  end

  def oa_config
    YAML.load_file("#{Rails.root}/config/openassets.yml").deep_symbolize_keys
  end

  # 最新のBlock Heightを取得
  def current_block_height
    oa_api.provider.getinfo['blocks'].to_i
  end

  # 最新のBlockTimeを取得
  def current_block_time
    block_hash = oa_api.provider.getblockhash(current_block_height)
    Time.at(oa_api.provider.getblock(block_hash)['time'])
  end

end
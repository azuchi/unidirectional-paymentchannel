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

end
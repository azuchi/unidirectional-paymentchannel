module PaymentChannel

  class Client

    attr_reader :endpoint

    def initialize(endpoint)
      @endpoint = endpoint
    end

    def request_new_pubkey
      RestClient.post("#{endpoint}/new_key", {})
    end

  end

end
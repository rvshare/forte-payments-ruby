module FortePayments
  class Error < StandardError
  end

  class Client
    include FortePayments::Client::Address
    include FortePayments::Client::Customer
    include FortePayments::Client::Paymethod
    include FortePayments::Client::Settlement
    include FortePayments::Client::Transaction

    attr_reader :api_key
    attr_reader :secure_key
    attr_reader :account_id
    attr_reader :location_id

    def initialize(options={})
      @live        = ENV['FORTE_LIVE'] && ENV['FORTE_LIVE'] != ''
      @api_key     = options[:api_key] || ENV['FORTE_API_KEY']
      @secure_key  = options[:secure_key] || ENV['FORTE_SECURE_KEY']
      @account_id  = options[:account_id] || ENV['FORTE_ACCOUNT_ID']
      @location_id = options[:location_id] || ENV['FORTE_LOCATION_ID']
      @proxy       = options[:proxy] || ENV['PROXY'] || ENV['proxy']
      @debug       = options[:debug]
    end

    def get(path, options={})
      make_request {
        connection.get(base_path + path, options)
      }
    end

    def post(path, req_body)
      make_request {
        connection.post do |req|
          req.url(base_path + path)
          req.body = req_body
        end
      }
    end

    def put(path, options={})
      make_request {
        connection.put(base_path + path, options)
      }
    end

    def delete(path, options={})
      make_request {
        connection.delete(base_path + path, options)
      }
    end

    private

    def make_request
      response = yield
      if response.success?
        response.body
      else
        raise FortePayments::Error, 'Unknown error' if response.body.nil?
        raise FortePayments::Error, response.body.dig('response', 'response_desc') || response.body
      end
    end

    def base_url
      @live ? "https://api.forte.net/v2" : "https://sandbox.forte.net/api/v2"
    end

    def base_path
      base_url + "/accounts/act_#{account_id}/locations/loc_#{location_id}"
    end

    def connection
      connection_options = {
        proxy: @proxy,
        headers: {
          accept: 'application/json',
          x_forte_auth_account_id: "act_#{account_id}"
        }
      }

      Faraday.new(connection_options) do |connection|
        connection.basic_auth(api_key, secure_key)
        connection.request  :json
        connection.response :json
        connection.response :logger if @debug
        connection.adapter  Faraday.default_adapter
      end
    end
  end
end

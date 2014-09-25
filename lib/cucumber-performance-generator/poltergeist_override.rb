module Capybara::Poltergeist::NetworkTraffic
  class Request
    attr_reader :response_parts

    def initialize(data, response_parts = [])
      @data           = data
      @response_parts = response_parts
    end

    def response_parts
      @response_parts
    end

    def url
      @data['url']
    end

    def method
      @data['method']
    end

    def data
      @data['data']
    end

    def headers
      @data['headers']
    end

    def time
      @data['time'] && Time.parse(@data['time'])
    end
  end
end

module Capybara::Poltergeist::NetworkTraffic
  class Response
    def initialize(data)
      @data = data
    end

    def url
      @data['url']
    end

    def status
      @data['status']
    end

    def status_text
      @data['statusText']
    end

    def headers
      @data['headers']
    end

    def redirect_url
      @data['redirectURL']
    end

    def body_size
      @data['bodySize']
    end

    def content_type
      @data['contentType']
    end

    def time
      @data['time'] && Time.parse(@data['time'])
    end
  end
end

# frozen_string_literal: true

module DiscourseJira
  class Api

    def self.make_request(endpoint)
      endpoint = "rest/api/2/#{endpoint}" unless endpoint.start_with?("rest/api/2/")
      uri = URI.join(SiteSetting.discourse_jira_url, endpoint)

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Authorization' => 'Basic ' + Base64.strict_encode64("#{SiteSetting.discourse_jira_username}:#{SiteSetting.discourse_jira_password}"),
        }

        request = yield(uri, headers)
        http.request(request)
      end
    end

    def self.get(endpoint)
      make_request(endpoint) do |uri, headers|
        Net::HTTP::Get.new(uri, headers)
      end
    end

    def self.post(endpoint, body)
      make_request(endpoint) do |uri, headers|
        request = Net::HTTP::Post.new(uri, headers)
        request.body = body.to_json

        request
      end
    end

  end
end

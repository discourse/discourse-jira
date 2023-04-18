# frozen_string_literal: true

module DiscourseJira
  class Api
    def self.get_version!
      if SiteSetting.discourse_jira_api_version.blank?
        data = JSON.parse(get("serverInfo"))
        SiteSetting.discourse_jira_api_version = data["version"]
      end

      SiteSetting.discourse_jira_api_version.split(".").first.to_i
    end

    def self.make_request(endpoint)
      if endpoint.start_with?("https://")
        uri = URI(endpoint)
      else
        endpoint = "rest/api/2/#{endpoint}" unless endpoint.start_with?("rest/api/2/")
        uri = URI.join(SiteSetting.discourse_jira_url, endpoint)
      end

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        headers = {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "Authorization" =>
            "Basic " +
              Base64.strict_encode64(
                "#{SiteSetting.discourse_jira_username}:#{SiteSetting.discourse_jira_password}",
              ),
        }

        request = yield(uri, headers)
        http.request(request)
      end
    end

    def self.get(endpoint)
      make_request(endpoint) { |uri, headers| Net::HTTP::Get.new(uri, headers) }
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

# frozen_string_literal: true

module DiscourseJira
  class InvalidApiResponse < ::StandardError
  end

  class Api
    INVALID_RESPONSE = "Invalid response from Jira API server"

    def self.get_version!
      if SiteSetting.discourse_jira_api_version == 0
        data = JSON.parse(get("serverInfo").body)
        SiteSetting.discourse_jira_api_version = data["versionNumbers"][0]
      end

      SiteSetting.discourse_jira_api_version
    end

    def self.createmeta_restricted?
      api_version = get_version!
      api_version >= 9 && api_version < 1000
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

    def self.getJSON(endpoint)
      response = get(endpoint)

      if response.code != "200"
        e = InvalidApiResponse.new(response.body.presence || "")
        e.set_backtrace(caller)
        Discourse.warn_exception(e, message: INVALID_RESPONSE, env: { endpoint: endpoint })
        return { error: INVALID_RESPONSE }
      end

      JSON.parse(response.body, symbolize_names: true)
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

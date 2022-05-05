# frozen_string_literal: true

module DiscourseJira
  class IssuesController < ::ApplicationController
    requires_plugin DiscourseJira

    before_action :ensure_logged_in
    before_action :ensure_can_create_jira_issue

    skip_before_action :check_xhr, :verify_authenticity_token, :ensure_logged_in, :ensure_can_create_jira_issue, only: [:webhook]

    def preflight
      hijack do
        projects_and_issue_types = Discourse.cache.fetch('discourse_jira_projects_and_issue_types', expires_in: 1.hour, force: true) do
          response = make_get_request('rest/api/2/project/search?expand=issueTypes')
          log("Jira verbose log:\n API result = #{response.body}")
          raise Discourse::NotFound if response.code != '200'

          json = JSON.parse(response.body, symbolize_names: true)
          json[:values].map do |project|
            issue_types = project[:issueTypes].map do |issue_type|
              next if issue_type[:subtask]

              { id: issue_type[:id], name: issue_type[:name] }
            end.compact

            {
              key: project[:key],
              name: project[:name],
              issue_types: issue_types
            }
          end
        end

        render json: {
          projects: projects_and_issue_types,
          email: current_user.email
        }
      end
    end

    def create
      raise Discourse::InvalidAccess if !SiteSetting.discourse_jira_enabled

      summary = I18n.t('discourse_jira.issue_title', title: params[:title])

      body_hash = {
        fields: {
          project: { key: params[:project_key] },
          summary: summary,
          description: params[:description],
          issuetype: { id: params[:issue_type_id] }
        }
      }

      hijack(info: "creating Jira issue for topic #{params[:topic_id]} and post_number #{params[:post_number]}") do
        response = make_post_request('rest/api/2/issue', body_hash)
        if response.code != '201'
          log("Bad Jira response: #{response.body}")
          return render_json_error(I18n.t('discourse_jira.bad_api_response', status_code: response.code), status: 422)
        end

        json = JSON.parse(response.body, symbolize_names: true)

        result = success_json.merge({
          issue_key: json[:key],
          issue_url: URI.join(SiteSetting.discourse_jira_url, "browse/#{json[:key]}").to_s,
        })

        post = Post.find_by(topic_id: params[:topic_id], post_number: params[:post_number])
        post.custom_fields['jira_issue_key'] = result[:issue_key]
        post.save_custom_fields

        if topic = Topic.find_by(id: params[:topic_id])
          if current_user.guardian.can_create_post_on_topic?(topic)
            topic.add_moderator_post(
              current_user,
              I18n.t('discourse_jira.small_action', title: summary, url: result[:issue_url]),
              post_type: Post.types[:small_action],
              action_code: 'jira_issue'
            )
          end
        end

        response = make_get_request(json[:self])
        post.custom_fields['jira_issue'] = response.body
        post.save_custom_fields

        render json: result
      end
    end

    def webhook
      if SiteSetting.discourse_jira_webhook_token.present?
        raise Discourse::InvalidAccess if !ActiveSupport::SecurityUtils.secure_compare(params[:t], SiteSetting.discourse_jira_webhook_token)
      else
        Rails.logger.warn('discourse_jira_webhook_token is empty. Set a token to ensure malicious requests are not handled.')
      end

      post = Post
        .joins(:_custom_fields)
        .find_by(_custom_fields: { name: 'jira_issue_key', value: params[:issue][:key] })
      raise Discourse::NotFound if post.blank?

      post.custom_fields['jira_issue'] = params[:issue].to_json
      post.save_custom_fields

      render json: success_json
    end

    private

    def ensure_can_create_jira_issue
      guardian.ensure_can_create_jira_issue!
    end

    def make_request(endpoint)
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

    def make_get_request(endpoint)
      make_request(endpoint) do |uri, headers|
        Net::HTTP::Get.new(uri, headers)
      end
    end

    def make_post_request(endpoint, body)
      make_request(endpoint) do |uri, headers|
        request = Net::HTTP::Post.new(uri, headers)
        request.body = body.to_json

        request
      end
    end

    def log(message)
      Rails.logger.warn(message) if SiteSetting.discourse_jira_verbose_log
    end
  end
end

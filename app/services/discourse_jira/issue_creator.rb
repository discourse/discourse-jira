# frozen_string_literal: true

module DiscourseJira
  class IssueCreator
    include ::DiscourseJira::Log

    attr_reader :post, :topic, :user, :fields

    class << self
      def create(post, user, fields = {})
        new(post, user, fields).create
      end
    end

    def initialize(post, user, fields = {})
      @post = post
      @topic = @post.topic
      @user = user
      @fields = fields.presence || generated_fields
    end

    def create
      return issue_data(post.jira_issue_key) if post.has_jira_issue?
      return if fields.blank?

      log(fields.inspect)

      response = Api.post("issue", { fields: fields })
      json =
        begin
          JSON.parse(response.body, symbolize_names: true)
        rescue StandardError
          {}
        end
      log(json.inspect)

      if response.code != "201"
        log("Bad Jira response: #{response.body}")
        errors = (json[:errors] || {}).values.join(" ")
        error_message =
          (
            if errors.present?
              I18n.t("discourse_jira.error_message", errors: errors)
            else
              I18n.t("discourse_jira.bad_api_response", status_code: response.code)
            end
          )

        raise Api.invalid_response_exception(response, message: error_message)
      end

      key = json[:key]
      result = issue_data(key)
      post.jira_issue_key = key

      if topic.present? && user.guardian.can_create_post_on_topic?(topic)
        topic.add_moderator_post(
          user,
          I18n.t("discourse_jira.small_action", title: fields[:summary], url: result[:issue_url]),
          post_type: Post.types[:whisper],
          action_code: "jira_issue",
        )
      end

      response = Api.get(json[:self])
      post.jira_issue = JSON.parse(response.body)

      Api.post(
        "issue/#{key}/remotelink",
        { object: { url: post.full_url, title: I18n.t("discourse_jira.issue_source") } },
      )

      result
    end

    def generated_fields
      category = topic&.category
      return if category.blank?

      project_id = category.custom_fields["jira_project_id"]
      return if project_id.blank?

      project = Project.find_by(id: project_id)
      return if project.blank?

      issue_type_id = category.custom_fields["jira_issue_type_id"]
      return if issue_type_id.blank?

      issue_type = IssueType.find_by(id: issue_type_id)
      return if issue_type.blank?

      summary = I18n.t("discourse_jira.issue_title", title: topic.title)

      {
        project: {
          key: project.key,
        },
        summary: summary,
        description: topic.formatted_post_history(post.post_number),
        issuetype: {
          id: issue_type.uid,
        },
      }
    end

    def issue_data(key)
      { issue_key: key, issue_url: URI.join(SiteSetting.discourse_jira_url, "browse/#{key}").to_s }
    end
  end
end

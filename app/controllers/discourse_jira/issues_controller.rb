# frozen_string_literal: true

module DiscourseJira
  class IssuesController < ::ApplicationController
    requires_plugin DiscourseJira::PLUGIN_NAME

    before_action :ensure_logged_in, except: [:webhook]
    before_action :ensure_can_create_jira_issue, except: [:webhook]
    before_action :ensure_can_add_jira_issue_to_post, only: %i[create attach]

    skip_before_action :check_xhr,
                       :verify_authenticity_token,
                       :redirect_to_login_if_required,
                       :preload_json,
                       only: [:webhook]

    def preflight
      render json: {
               projects:
                 ActiveModel::ArraySerializer.new(
                   Project.all,
                   each_serializer: JiraProjectSerializer,
                 ).as_json,
               email: current_user.email,
             }
    end

    def fields
      params.require(:project_id)
      params.require(:issue_type_id)

      fields =
        ProjectIssueType.find_by(
          project_id: params[:project_id].to_i,
          issue_type_id: params[:issue_type_id].to_i,
        ).fetch_fields

      render json: { fields: fields }
    end

    def create
      params.require(:project_id)
      summary = I18n.t("discourse_jira.issue_title", title: params[:title])
      issue_type = IssueType.find_by(id: params[:issue_type_id])
      raise Discourse::NotFound if issue_type.blank?

      fields = {
        project: {
          key: project.key,
        },
        summary: summary,
        description: params[:description],
        issuetype: {
          id: issue_type.uid,
        },
      }

      (params[:fields] || []).each do |_, data|
        next if data.blank?
        next if data[:value].blank? && data[:required] != "true"

        case data[:field_type]
        when "array"
          fields[data[:key]] = data[:value].map { |v| { id: v } }
        when "option"
          fields[data[:key]] = { id: data[:value] }
        else
          fields[data[:key]] = data[:value]
        end
      end
      log(fields.inspect)

      hijack(
        info:
          "creating Jira issue for topic #{params[:topic_id]} and post_number #{params[:post_number]}",
      ) do
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
          render_json_error(error_message, status: 422)
          break
        end

        result =
          success_json.merge(
            {
              issue_key: json[:key],
              issue_url: URI.join(SiteSetting.discourse_jira_url, "browse/#{json[:key]}").to_s,
            },
          )

        post.jira_issue_key = result[:issue_key]

        if topic = Topic.find_by(id: params[:topic_id])
          if current_user.guardian.can_create_post_on_topic?(topic)
            topic.add_moderator_post(
              current_user,
              I18n.t("discourse_jira.small_action", title: summary, url: result[:issue_url]),
              post_type: Post.types[:whisper],
              action_code: "jira_issue",
            )
          end
        end

        response = Api.get(json[:self])
        post.custom_fields["jira_issue"] = response.body
        post.save_custom_fields

        render json: result
      end
    end

    def attach
      raise Discourse::InvalidAccess if !SiteSetting.discourse_jira_enabled

      hijack(
        info:
          "attaching Jira issue for topic #{params[:topic_id]} and post_number #{params[:post_number]}",
      ) do
        response = Api.get("issue/#{params[:issue_key]}")

        if response.code != "200"
          log("Bad Jira response: #{response.body}")
          render_json_error(
            I18n.t("discourse_jira.bad_api_response", status_code: response.code),
            status: 422,
          )
          break
        end

        json = JSON.parse(response.body, symbolize_names: true)

        result =
          success_json.merge(
            {
              issue_key: json[:key],
              issue_url: URI.join(SiteSetting.discourse_jira_url, "browse/#{json[:key]}").to_s,
            },
          )

        post.jira_issue_key = result[:issue_key]

        if topic = Topic.find_by(id: params[:topic_id])
          if current_user.guardian.can_create_post_on_topic?(topic)
            topic.add_moderator_post(
              current_user,
              I18n.t(
                "discourse_jira.small_action",
                title: json[:fields][:summary],
                url: result[:issue_url],
              ),
              post_type: Post.types[:whisper],
              action_code: "jira_issue",
            )
          end
        end

        response = Api.get(json[:self])
        post.custom_fields["jira_issue"] = response.body
        post.save_custom_fields

        render json: result
      end
    end

    def webhook
      log(params.inspect)

      if SiteSetting.discourse_jira_webhook_token.present?
        params.require(:t)
        if !ActiveSupport::SecurityUtils.secure_compare(
             params[:t],
             SiteSetting.discourse_jira_webhook_token,
           )
          raise Discourse::InvalidAccess
        end
      else
        Rails.logger.warn(
          "discourse_jira_webhook_token is empty. Set a token to ensure malicious requests are not handled.",
        )
      end

      event = params[:webhookEvent]
      issue_event = params[:issue_event_type_name]

      if event == "jira:issue_updated"
        issue = params[:issue]
        post =
          Post.joins(:_custom_fields).find_by(
            _custom_fields: {
              name: "jira_issue_key",
              value: issue[:key],
            },
          )
        raise Discourse::NotFound if post.blank?

        post.custom_fields["jira_issue"] = issue.to_json
        post.save_custom_fields

        if SiteSetting.discourse_jira_close_topic_on_resolve && issue[:fields][:resolution].present?
          topic = post.topic
          if post.post_number == 1 && topic&.open?
            topic.update_status("closed", true, Discourse.system_user)
          end
        end

        if SiteSetting.discourse_jira_sync_issue_comments && issue_event == "issue_commented" &&
             post.is_first_post?
          topic = post.topic
          comment = params[:comment]

          PostCreator.create!(
            Discourse.system_user,
            topic_id: topic.id,
            raw: comment[:body],
            skip_validations: true,
            custom_fields: {
              "jira_comment_id" => comment[:id],
            },
          )
        end
      end

      render json: success_json
    end

    private

    def project
      @project ||= Project.find_by(id: params[:project_id])
    end

    def ensure_can_create_jira_issue
      guardian.ensure_can_create_jira_issue!
    end

    def ensure_can_add_jira_issue_to_post
      if post.blank?
        raise Discourse::NotFound
      elsif post.has_jira_issue?
        log "Post #{post.id} already has a Jira issue"
        raise Discourse::InvalidAccess
      end
    end

    def post
      params.require(:topic_id)
      params.require(:post_number)
      @post ||= Post.find_by(topic_id: params[:topic_id], post_number: params[:post_number])
    end

    def log(message)
      Rails.logger.warn("Jira verbose log:\n #{message}") if SiteSetting.discourse_jira_verbose_log
    end
  end
end

# frozen_string_literal: true

# name: discourse-jira
# about: Allow creation of JIRA issues from Discourse
# version: 0.0.2
# authors: Discourse
# url: https://github.com/discourse/discourse-jira
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :discourse_jira_enabled

register_asset "stylesheets/common/discourse-jira.scss"

%w[paperclip fab-jira].each { |icon| register_svg_icon icon }

require_relative "lib/discourse_jira/api"
require_relative "lib/discourse_jira/engine"

after_initialize do
  topic_view_post_custom_fields_allowlister do |user|
    user&.staff? ? %w[jira_issue_key jira_issue] : []
  end

  add_to_class(:guardian, :can_create_jira_issue?) do
    SiteSetting.discourse_jira_enabled && is_staff?
  end

  add_to_class(:post, :jira_issue) do
    begin
      JSON.parse(custom_fields["jira_issue"])
    rescue StandardError
      nil
    end
  end

  add_to_class(:post, :has_jira_issue?) { custom_fields["jira_issue"].present? }

  add_to_class(:post, :jira_issue_key=) do |key|
    custom_fields["jira_issue_key"] = key
    save_custom_fields

    if is_first_post?
      topic.custom_fields["jira_issue_key"] = key
      topic.save_custom_fields
    end
  end

  add_to_serializer(:current_user, :can_create_jira_issue, false) { true }

  add_to_serializer(:current_user, :include_can_create_jira_issue?) { scope.can_create_jira_issue? }

  add_to_serializer(:post, :jira_issue, false) { object.jira_issue }

  add_to_serializer(:post, :include_jira_issue?) do
    scope.can_create_jira_issue? && object.custom_fields["jira_issue"].present?
  end
end

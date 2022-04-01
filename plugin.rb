# frozen_string_literal: true

# name: discourse-jira
# about: Allow creation of JIRA issues from Discourse
# version: 0.0.1
# authors: Discourse
# url: https://github.com/discourse/discourse-jira
# required_version: 2.7.0

enabled_site_setting :discourse_jira_enabled

register_asset 'stylesheets/common/discourse-jira.scss'

require_relative 'lib/discourse-jira/engine'

after_initialize do
  add_to_class(:guardian, :can_create_jira_issue?) do
    SiteSetting.discourse_jira_enabled && is_staff?
  end

  add_to_serializer(:current_user, :can_create_jira_issue, false) do
    true
  end

  add_to_serializer(:current_user, :include_can_create_jira_issue?) do
    scope.can_create_jira_issue?
  end
end

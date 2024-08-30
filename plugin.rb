# frozen_string_literal: true

# name: discourse-jira
# about: Allow synchronization of JIRA projects, issue types, fields, and issue statuses from Discourse.
# meta_topic_id: 274045
# version: 0.0.2
# authors: Discourse
# url: https://github.com/discourse/discourse-jira
# required_version: 2.7.0

enabled_site_setting :discourse_jira_enabled

register_asset "stylesheets/common/discourse-jira.scss"

%w[paperclip fab-jira].each { |icon| register_svg_icon icon }

require_relative "lib/discourse_jira/api"
require_relative "lib/discourse_jira/engine"
require_relative "lib/discourse_jira/log"

after_initialize do
  SeedFu.fixture_paths << Rails.root.join("plugins", "discourse-jira", "db", "fixtures").to_s

  reloadable_patch do |plugin|
    Post.register_custom_field_type("jira_issue", :json)
    Category.register_custom_field_type("jira_project_id", :integer)
    Category.register_custom_field_type("jira_num_likes_auto_create_issue", :integer)
    Category.register_custom_field_type("jira_issue_type_id", :integer)
  end

  topic_view_post_custom_fields_allowlister do |user|
    user&.staff? ? %w[jira_issue_key jira_issue] : []
  end

  on(:site_setting_changed) do |name|
    Jobs.enqueue(:sync_jira) if %i[discourse_jira_enabled discourse_jira_url].include?(name)
  end

  on(:like_created) do |post_action, post_action_creator|
    Jobs.enqueue(:jira_post_liked, post_id: post_action.post_id)
  end

  add_to_class(:guardian, :can_create_jira_issue?) do
    SiteSetting.discourse_jira_enabled &&
      user&.in_any_groups?(SiteSetting.discourse_jira_allowed_groups_map)
  end

  add_to_class(:post, :jira_issue) do
    begin
      JSON.parse(custom_fields["jira_issue"])
    rescue StandardError
      nil
    end
  end

  add_to_class(:post, :has_jira_issue?) { custom_fields["jira_issue"].present? }

  add_to_class(:post, :jira_issue_key) { custom_fields["jira_issue_key"].presence }

  add_to_class(:post, :jira_issue_key=) do |key|
    custom_fields["jira_issue_key"] = key
    save_custom_fields

    if is_first_post?
      topic.custom_fields["jira_issue_key"] = key
      topic.save_custom_fields
    end
  end

  add_to_class(:post, :jira_issue) { custom_fields["jira_issue"] }

  add_to_class(:post, :jira_issue=) do |issue|
    custom_fields["jira_issue"] = issue
    save_custom_fields
    topic.jira_issue_status = issue.dig("fields", "status", "name") if is_first_post?
  end

  add_to_class(:topic, :jira_issue_status=) do |status|
    if SiteSetting.tagging_enabled && SiteSetting.discourse_jira_issue_tags_enabled
      tag_name = "status-#{status.downcase.gsub(/\s+/, "-")}"
      tag = Tag.find_or_create_by(name: tag_name)

      tag_group = TagGroup.find_by(name: "Jira Issue Status")
      TagGroupMembership.find_or_create_by(tag_group_id: tag_group.id, tag_id: tag.id)

      if self.topic_tags.where(tag_id: tag.id).empty?
        TopicTag.joins(:tag).where(topic_id: self.id).where("tags.name LIKE 'status-%'").delete_all
        DiscourseTagging.add_or_create_tags_by_name(self, ["jira-issue", tag.name])
      end
    end
  end

  add_to_class(:topic, :formatted_post_history) do |post_number|
    last_post_number = post_number.clamp(1, highest_post_number)
    posts = ordered_posts.where("post_number <= ?", last_post_number)

    args = {}
    args[:topic] = self
    args[:posts] = posts.collect do |post|
      summary = {}
      summary[:username] = post.username
      summary[:created_at] = post.created_at
      summary[:body] = post.excerpt(
        1000,
        strip_links: true,
        text_entities: true,
        markdown_images: true,
      )
      summary
    end

    template =
      File.read(Rails.root.join("plugins/discourse-jira/lib/templates/topic_summary.mustache"))

    Mustache.render(template, args).strip
  end

  add_to_serializer(:current_user, :can_create_jira_issue, respect_plugin_enabled: false) do
    SiteSetting.discourse_jira_enabled &&
      user&.in_any_groups?(SiteSetting.discourse_jira_allowed_groups_map)
  end

  add_to_serializer(:current_user, :include_can_create_jira_issue?) { scope.can_create_jira_issue? }

  add_to_serializer(:post, :jira_issue, respect_plugin_enabled: false) { object.jira_issue }

  add_to_serializer(:post, :include_jira_issue?) do
    scope.can_create_jira_issue? && object.custom_fields["jira_issue"].present?
  end
end

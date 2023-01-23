# frozen_string_literal: true

module DiscourseJira
  class PostsController < ::ApplicationController
    requires_plugin DiscourseJira

    before_action :ensure_logged_in
    before_action :ensure_can_create_jira_issue

    def formatted_post_history
      topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound if !topic
      guardian.ensure_can_see!(topic)

      last_post_number = params[:post_number].to_i.clamp(1, topic.highest_post_number)
      posts = topic.ordered_posts.where("post_number <= ?", last_post_number)

      args = {}
      args[:topic] = topic
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
        File.read(
          Rails.root.join(
            Rails.root,
            "plugins/discourse-jira/lib/templates/topic_summary.mustache",
          ),
        )
      result = Mustache.render(template, args).strip

      render json: { formatted_post_history: result }
    end

    private

    def ensure_can_create_jira_issue
      guardian.ensure_can_create_jira_issue!
    end
  end
end

# frozen_string_literal: true

module ::Jobs
  class JiraPostLiked < ::Jobs::Base
    def execute(args)
      return unless SiteSetting.discourse_jira_enabled
      return if SiteSetting.discourse_jira_url.blank?

      post_id = args[:post_id]
      post = Post.find_by(id: post_id)
      return if post.blank? || post.post_number != 1

      category = post.topic&.category
      return if category.blank?

      required_num_likes = category.custom_fields["jira_num_likes_auto_create_issue"].to_i
      return if required_num_likes <= 0 || post.like_count < required_num_likes

      project_id = category.custom_fields["jira_project_id"]
      issue_type_id = category.custom_fields["jira_issue_type_id"]
      return if project_id.blank? || issue_type_id.blank?

      DiscourseJira::IssueCreator.create(post, Discourse.system_user)
    end
  end
end

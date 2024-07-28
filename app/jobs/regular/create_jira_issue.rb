# frozen_string_literal: true

module ::Jobs
  class CreateJiraIssue < ::Jobs::Base

    def execute(args)
      post_id = args[:post_id]
      post = Post.find_by(id: post_id)
      return if post.blank?

      DiscourseJira::IssueCreator.create(post, Discourse.system_user)
    end
  end
end

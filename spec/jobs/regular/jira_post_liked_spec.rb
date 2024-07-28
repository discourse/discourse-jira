# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jobs::JiraPostLiked do
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:post) { Fabricate(:post, topic: topic, post_number: 1, like_count: 3) }
  subject(:execute) { job.execute(post_id: post.id) }

  let(:job) { described_class.new }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://test.atlassian.net"
    category.custom_fields["jira_num_likes_auto_create_issue"] = 3
    category.custom_fields["jira_project_id"] = 1
    category.custom_fields["jira_issue_type_id"] = 1
    category.save_custom_fields
  end

  it "does nothing if the post is not the first post" do
    post.update!(post_number: 2)
    DiscourseJira::IssueCreator.expects(:create).never
    execute()
  end

  it "does nothing if the post does not have the required likes" do
    post.update!(like_count: 2)
    DiscourseJira::IssueCreator.expects(:create).never
    execute()
  end

  it "does nothing if the category does not have the required custom fields" do
    category.custom_fields["jira_num_likes_auto_create_issue"] = nil
    category.save_custom_fields
    DiscourseJira::IssueCreator.expects(:create).never
    execute()
  end

  it "creates a new issue" do
    DiscourseJira::IssueCreator.expects(:create).with(post, Discourse.system_user)
    execute()
  end
end

# frozen_string_literal: true

require "rails_helper"
require_relative "../spec_helper"

RSpec.describe DiscourseJira::Project do
  fab!(:topic)

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_issue_tags_enabled = true
  end

  describe ".jira_issue_status=" do
    before do
      SiteSetting.tagging_enabled = true
    end

    it "sets the issue status for the project" do
      topic.jira_issue_status = "To Do"
      expect(topic.tags.pluck(:name)).to eq(["jira-issue", "status-to-do"])
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jobs::SyncJira do
  subject(:execute) { job.execute({}) }

  let(:job) { described_class.new }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://jira.example.com"
  end

  it "syncs issue types and projects" do
    ::DiscourseJira::IssueType.expects(:sync!).once
    ::DiscourseJira::Project.expects(:sync!).once
    execute
  end

  it "does not sync if jira URL is blank" do
    SiteSetting.discourse_jira_url = ""
    ::DiscourseJira::IssueType.expects(:sync!).never
    ::DiscourseJira::Project.expects(:sync!).never
    execute
  end
end

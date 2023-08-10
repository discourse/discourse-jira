# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseJira::IssueType do
  let(:api_url) { "https://jira.example.com/rest/api/2" }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://jira.example.com"
    SiteSetting.discourse_jira_username = "jira"
    SiteSetting.discourse_jira_password = "password"
    SiteSetting.discourse_jira_api_version = 9
  end

  describe ".sync!" do
    it "syncs issue types from Jira" do
      issue_types = [{ id: 100, name: "Task" }, { id: 101, name: "Bug" }]

      stub_request(:get, "#{api_url}/issuetype").to_return(status: 200, body: issue_types.to_json)

      expect { described_class.sync! }.to change { described_class.count }.from(0).to(2)

      expect(described_class.pluck(:uid, :name)).to eq(issue_types.pluck(:id, :name))
    end
  end
end

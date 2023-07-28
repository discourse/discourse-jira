# frozen_string_literal: true

require "rails_helper"
require_relative "../spec_helper"

RSpec.describe DiscourseJira::Project do
  let(:api_url) { "https://jira.example.com/rest/api/2" }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://jira.example.com"
    SiteSetting.discourse_jira_username = "jira"
    SiteSetting.discourse_jira_password = "password"
    SiteSetting.discourse_jira_api_version = 9
  end

  describe ".sync!" do
    let(:projects) do
      [
        { id: 100, key: "TEST", name: "Test Project" },
        { id: 101, key: "TEST2", name: "Test Project 2" },
      ]
    end

    before do
      stub_request(:get, "#{api_url}/project").to_return(status: 200, body: projects.to_json)
    end

    it "syncs projects from Jira" do
      expect { described_class.sync! }.to change { described_class.count }.from(0).to(2)

      expect(described_class.pluck(:uid, :key, :name)).to eq(projects.pluck(:id, :key, :name))
    end

    it "syncs projects from Jira using createmeta" do
      SiteSetting.discourse_jira_api_version = 8
      stub_request(
        :get,
        "#{api_url}/issue/createmeta?expand=projects.issuetypes.fields&projectIds=100,101",
      ).to_return(status: 200, body: get_jira_response("createmeta.json"))

      described_class.sync!

      expect(described_class.pluck(:uid, :key, :name)).to eq(projects.pluck(:id, :key, :name))
      expect(DiscourseJira::IssueType.pluck(:uid, :name)).to eq([[1, "Bug"], [2, "Task"]])
      expect(DiscourseJira::Field.pluck(:key)).to eq(%w[os browser])
    end
  end
end

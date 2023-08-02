# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseJira::IssueType do
  let(:api_url) { "https://jira.example.com/rest/api/2" }
  fab!(:project) { Fabricate(:jira_project) }

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

      stub_request(:get, "#{api_url}/issue/createmeta/#{project.key}/issuetypes").to_return(
        status: 200,
        body: { values: issue_types }.to_json,
      )

      expect { described_class.sync! }.to change { described_class.count }.from(0).to(2)

      expect(described_class.pluck(:uid, :name)).to eq(issue_types.pluck(:id, :name))
    end

    it "syncs issue types from Jira using createmeta endpoint" do
      SiteSetting.discourse_jira_api_version = 8
      project.update(uid: 100)

      stub_request(
        :get,
        "#{api_url}/issue/createmeta?expand=projects.issuetypes.fields&projectIds=100",
      ).to_return(status: 200, body: get_jira_response("createmeta.json"))

      described_class.sync!

      expect(described_class.pluck(:uid, :name)).to eq([[1, "Bug"]])
      expect(DiscourseJira::Field.pluck(:key)).to eq(%w[os])
    end
  end
end

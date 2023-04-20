# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseJira::Project do
  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://jira.example.com"
    SiteSetting.discourse_jira_username = "jira"
    SiteSetting.discourse_jira_password = "password"
    SiteSetting.discourse_jira_api_version = 9
  end

  describe ".sync!" do
    it "syncs projects from Jira" do
      projects = [
        { id: 100, key: "TEST", name: "Test Project" },
        { id: 101, key: "TEST2", name: "Test Project 2" },
      ]

      stub_request(:get, "https://jira.example.com/rest/api/2/project").to_return(
        status: 200,
        body: projects.to_json,
      )

      expect { described_class.sync! }.to change { described_class.count }.from(0).to(2)

      expect(described_class.pluck(:uid, :key, :name)).to eq(projects.pluck(:id, :key, :name))
    end
  end
end

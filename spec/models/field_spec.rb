# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseJira::Field do
  fab!(:project) { Fabricate(:jira_project) }
  fab!(:issue_type) { Fabricate(:jira_issue_type, project: project) }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://jira.example.com"
    SiteSetting.discourse_jira_username = "jira"
    SiteSetting.discourse_jira_password = "password"
    SiteSetting.discourse_jira_api_version = 9
  end

  describe ".sync!" do
    it "syncs fields from Jira" do
      fields = [
        {
          id: 100,
          name: "Platform",
          schema: {
            type: "string",
          },
          operations: ["set"],
          fieldId: "platform",
          required: true,
        },
        {
          id: 101,
          name: "Device",
          schema: {
            type: "string",
          },
          operations: ["set"],
          fieldId: "device",
          required: false,
        },
        {
          id: 102,
          name: "Browser",
          schema: {
            type: "option",
            items: "string",
          },
          operations: ["set"],
          fieldId: "browser",
          required: false,
          allowedValues: [{ id: "chrome", value: "Chrome" }, { id: "firefox", value: "Firefox" }],
        },
      ]

      stub_request(
        :get,
        "https://jira.example.com/rest/api/2/issue/createmeta/#{project.key}/issuetypes/#{issue_type.uid}",
      ).to_return(status: 200, body: JSON.dump(values: fields))

      expect { described_class.sync! }.to change { described_class.count }.from(0).to(3)

      expect(described_class.pluck(:key, :name, :field_type)).to eq(
        fields.map { |f| [f[:fieldId], f[:name], f[:schema][:type]] },
      )
    end
  end
end

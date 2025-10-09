# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseJira::ProjectIssueType do
  fab!(:project, :jira_project)
  fab!(:issue_type, :jira_issue_type)

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://jira.example.com"
    SiteSetting.discourse_jira_username = "jira"
    SiteSetting.discourse_jira_password = "password"
    SiteSetting.discourse_jira_api_version = 9
    DiscourseJira::ProjectIssueType.create!(project: project, issue_type: issue_type)
  end

  describe ".fetch_fields" do
    it "get fields from Jira" do
      data = [
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
        "https://jira.example.com/rest/api/2/issue/createmeta/#{project.uid}/issuetypes/#{issue_type.uid}",
      ).to_return(status: 200, body: JSON.dump(values: data))

      fields = DiscourseJira::ProjectIssueType.last.fetch_fields

      expect(fields.size).to eq(3)
      expect(fields.pluck(:key, :name, :field_type)).to eq(
        data.map { |f| [f[:fieldId], f[:name], f[:schema][:type]] },
      )
    end
  end
end

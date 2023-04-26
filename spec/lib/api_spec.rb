# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::DiscourseJira::Api do
  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://jira.example.com"
    SiteSetting.discourse_jira_username = "jira"
    SiteSetting.discourse_jira_password = "password"
  end

  describe ".get_version!" do
    it "returns the API version" do
      stub_request(:get, "https://jira.example.com/rest/api/2/serverInfo").to_return(
        status: 200,
        body: {
          baseUrl: "https://jira.common.bluescape.com",
          version: "9.4.3",
          versionNumbers: [9, 4, 3],
          deploymentType: "Server",
          buildNumber: 940_003,
          buildDate: "2023-02-14T00:00:00.000+0000",
          databaseBuildNumber: 940_003,
          serverTime: "2023-04-20T09:37:42.687+0000",
          scmInfo: "274jf279485112dfg846632b627916e8cd84833fe47f7e7",
          serverTitle: "Provider",
        }.to_json,
      )

      expect(described_class.get_version!).to eq(9)
      expect(described_class.createmeta_restricted?).to be_truthy
      expect(SiteSetting.discourse_jira_api_version).to eq(9)
    end
  end
end

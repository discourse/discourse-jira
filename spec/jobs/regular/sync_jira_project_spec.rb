# frozen_string_literal: true

RSpec.describe ::Jobs::SyncJiraProject do
  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://some.jira.endpoint.com"
  end

  describe "#execute" do
    it "raises an error if project_uid is missing" do
      expect { described_class.new.execute({}) }.to raise_error(Discourse::InvalidParameters)
    end

    it "raises the right error when API call is rate limited" do
      stub_request(
        :get,
        "https://some.jira.endpoint.com/rest/api/2/project/123?expand=issueTypes",
      ).to_return(status: 429, headers: { "Retry-After" => "5" })

      expect { described_class.new.execute(project_uid: 123) }.to raise_error(
        ::Jobs::SyncJiraProject::RateLimited,
      ) do |error|
        expect(error.message).to eq("5")
      end
    end

    it "syncs issue types when API call is successful" do
      response_data = { someData: true }

      stub_request(
        :get,
        "https://some.jira.endpoint.com/rest/api/2/project/123?expand=issueTypes",
      ).to_return(status: 200, body: response_data.to_json)

      DiscourseJira::Project.any_instance.expects(:sync_issue_types!).with(response_data).once

      described_class.new.execute(project_uid: 123)
    end

    it "returns a DiscourseJira::InvalidApiResponse error for other API failures" do
      stub_request(
        :get,
        "https://some.jira.endpoint.com/rest/api/2/project/123?expand=issueTypes",
      ).to_return(status: 500)

      api_error = described_class.new.execute(project_uid: 123)

      expect(api_error).to be_a(DiscourseJira::InvalidApiResponse)
    end
  end
end

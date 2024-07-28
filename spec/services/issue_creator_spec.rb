# frozen_string_literal: true

require "rspec"

RSpec.describe ::DiscourseJira::IssueCreator do
  let!(:issue_key) { "TEST-123" }
  let!(:issue_api_url) { "https://test.atlassian.net/rest/api/2/issue/TEST-123" }
  let!(:issue_url) { "https://test.atlassian.net/browse/TEST-123" }

  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:post) { Fabricate(:post, topic: topic) }
  fab!(:admin)

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_username = "test"
    SiteSetting.discourse_jira_password = "test"
    SiteSetting.discourse_jira_url = "https://test.atlassian.net"

    stub_request(:post, "https://test.atlassian.net/rest/api/2/issue")
        .with(body: {
          fields: {
            project: { key: "DIS" },
            summary: I18n.t("discourse_jira.issue_title", title: topic.title),
            description: topic.formatted_post_history(post.post_number),
            issuetype: { id: 2001 },
          },
        }.to_json)
        .to_return(status: 201, body: {
          key: issue_key,
          self: issue_api_url ,
        }.to_json)

      stub_request(:get, issue_api_url)
        .to_return(status: 200, body: {
          key: issue_key,
          fields: {
            summary: "Test issue",
            description: "Test description",
            issuetype: { id: "1" },
          },
          self: issue_api_url,
        }.to_json)

      stub_request(:post, "#{issue_api_url}/remotelink")
        .with(body: {
          object: { url: post.full_url, title: I18n.t("discourse_jira.issue_source") },
        }.to_json)
        .to_return(status: 201, body: {
          id: "1",
          self: "#{issue_api_url}/remotelink/1",
        }.to_json)
  end

  describe "#create" do
    it "creates a new issue" do
      project = DiscourseJira::Project.create!(uid: 1, key: "DIS", name: "Discourse")
      issue_type = project.issue_types.create!(id: 10_001, uid: 2001, name: "Task")

      category.custom_fields["jira_project_id"] = project.id
      category.custom_fields["jira_issue_type_id"] = issue_type.id
      category.save_custom_fields

      result = described_class.create(post, admin)

      expect(result[:issue_key]).to eq(issue_key)
      expect(result[:issue_url]).to eq(issue_url)
      expect(post.jira_issue_key).to eq(issue_key)
    end

    it "creates a new issue with fields param" do
      described_class.any_instance.expects(:generated_fields).never

      result = described_class.create(post, admin, {
        project: { key: "DIS" },
        summary: I18n.t("discourse_jira.issue_title", title: topic.title),
        description: topic.formatted_post_history(post.post_number),
        issuetype: { id: 2001 },
      })

      expect(result[:issue_key]).to eq(issue_key)
      expect(result[:issue_url]).to eq(issue_url)
      expect(post.jira_issue_key).to eq(issue_key)
    end
  end
end

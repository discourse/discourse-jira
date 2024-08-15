# frozen_string_literal: true

require "rails_helper"
require "json"
require_relative "../spec_helper"

describe DiscourseJira::IssuesController do
  let(:admin) { Fabricate(:admin) }
  let(:user) { Fabricate(:user, trust_level: 2, refresh_auto_groups: true) }
  let(:issue_response) { get_jira_response("issue.response") }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://example.com/"
    SiteSetting.discourse_jira_api_version = 8
  end

  describe "#preflight" do
    it "should return a list of projects and issue types" do
      sign_in(admin)

      project = DiscourseJira::Project.create!(uid: 1, key: "DIS", name: "Discourse")
      issue_type_1 = project.issue_types.create!(id: 10_001, uid: 2001, name: "Task")
      issue_type_2 = project.issue_types.create!(id: 10_002, uid: 2002, name: "Epic")

      get "/jira/issues/preflight.json"
      expect(response.parsed_body).to eq(
        {
          "email" => admin.email,
          "projects" => [
            {
              "id" => project.id,
              "name" => project.name,
              "key" => project.key,
              "issue_types" => [
                { "id" => issue_type_1.id, "name" => issue_type_1.name },
                { "id" => issue_type_2.id, "name" => issue_type_2.name },
              ],
            },
          ],
        },
      )
    end
  end

  describe "#create" do
    let(:issue_type) { Fabricate(:jira_issue_type) }
    let(:project) { Fabricate(:jira_project) }

    it "requires user to be signed in" do
      post "/jira/issues.json"
      expect(response.status).to eq(403)
    end

    it "must be enabled" do
      SiteSetting.discourse_jira_enabled = false
      sign_in(admin)

      post "/jira/issues.json"
      expect(response.status).to eq(404)
    end

    it "create a Jira issue and " do
      sign_in(admin)
      post = Fabricate(:post)

      stub_request(:post, "https://example.com/rest/api/2/issue").with(
        body:
          "{\"fields\":{\"project\":{\"key\":\"#{project.key}\"},\"summary\":\"[Discourse] \",\"description\":\"This is a bug\",\"issuetype\":{\"id\":#{issue_type.uid}},\"software\":\"value\",\"platform\":{\"id\":\"windows\"}}}",
      ).to_return(
        status: 201,
        body: '{"id":"10041","key":"DIS-42","self":"https://example.com/rest/api/2/issue/10041"}',
        headers: {
        },
      )

      stub_request(:get, "https://example.com/rest/api/2/issue/10041").to_return(
        status: 200,
        body: issue_response,
      )

      stub_request(:post, "https://example.com/rest/api/2/issue/DIS-42/remotelink").to_return(
        status: 201,
        body: { id: "1", self: "https://example.com/rest/api/2/issue/DIS-42/remotelink/1" }.to_json,
      )

      expect do
        post "/jira/issues.json",
             params: {
               project_id: project.id,
               description: "This is a bug",
               issue_type_id: issue_type.id,
               topic_id: post.topic_id,
               post_number: post.post_number,
               fields: {
                 "0": {
                   key: "software",
                   value: "value",
                 },
                 "1": {
                   key: "platform",
                   value: "windows",
                   field_type: "option",
                 },
                 "2": {
                   key: "customfield_10010",
                   field_type: "array",
                   required: "false",
                 },
               },
             }
      end.to change { Post.count }.by(1)
      expect(response.parsed_body["issue_key"]).to eq("DIS-42")
      expect(response.parsed_body["issue_url"]).to eq("https://example.com/browse/DIS-42")

      post.reload
      expect(post.custom_fields["jira_issue_key"]).to eq("DIS-42")
      expect(post.custom_fields["jira_issue"]).to eq(JSON.parse(issue_response))
      expect(Post.last.post_type).to eq(Post.types[:whisper])
    end

    it "responds with proper error message" do
      sign_in(admin)
      post = Fabricate(:post)

      stub_request(:post, "https://example.com/rest/api/2/issue").to_return(
        status: 400,
        body:
          '{"errorMessages":[],"errors":{"versions":"Affects Version/s is required.","components":"Component/s is required."}}',
        headers: {
        },
      )

      post "/jira/issues.json",
           params: {
             project_id: project.id,
             description: "This is a bug",
             issue_type_id: issue_type.id,
             topic_id: post.topic_id,
             post_number: post.post_number,
             fields: [],
           }

      expect(response.parsed_body["errors"][0]).to eq(
        I18n.t(
          "discourse_jira.error_message",
          errors: "Affects Version/s is required. Component/s is required.",
        ),
      )
    end

    describe "group access" do
      before do
        SiteSetting.discourse_jira_allowed_groups = Group::AUTO_GROUPS[:moderators]
        Group.refresh_automatic_groups!
      end

      describe "regular user with insufficient permissions" do
        it "does not allow access" do
          sign_in(user)

          post "/jira/issues.json"
          expect(response.status).to eq(403)
        end
      end

      describe "user in group with permission" do
        it "allows access" do
          post = Fabricate(:post)
          project = Fabricate(:jira_project, uid: 2)

          sign_in(user)

          mods = Group.find(Group::AUTO_GROUPS[:moderators])
          mods.add(user)

          response = post "/jira/issues.json",
                      params: {
                        project_id: project.id,
                        issue_type_id: issue_type.id,
                        topic_id: post.topic_id,
                        post_number: post.post_number,
                      }

          expect(response).to eq(200)
        end
      end
    end
  end

  describe "#fields" do
    fab!(:project) { Fabricate(:jira_project, uid: 2) }
    fab!(:issue_type) { Fabricate(:jira_issue_type, uid: 7) }

    it "returns a list of fields for a given issue type" do
      sign_in(admin)

      DiscourseJira::ProjectIssueType.create!(project: project, issue_type: issue_type)
      stub_request(
        :get,
        "https://example.com/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields&issuetypeIds=#{issue_type.uid}&projectIds=#{project.uid}",
      ).to_return(
        status: 200,
        body: {
          projects: [
            {
              issuetypes: [
                {
                  fields: {
                    software: {
                      required: true,
                      schema: {
                        type: "string",
                      },
                      name: "Software",
                      operations: ["set"],
                    },
                    platform: {
                      required: false,
                      schema: {
                        type: "option",
                      },
                      name: "Platform",
                      allowedValues: [{ id: 5, value: "Windows" }, { id: 6, value: "Mac" }],
                      operations: ["set"],
                    },
                  },
                },
              ],
            },
          ],
        }.to_json,
      )

      get "/jira/issue/createmeta.json?project_id=#{project.id}&issue_type_id=#{issue_type.id}"
      expect(response.parsed_body["fields"]).to eq(
        [
          {
            "field_type" => "string",
            "key" => "software",
            "name" => "Software",
            "options" => nil,
            "required" => true,
          },
          {
            "field_type" => "option",
            "key" => "platform",
            "name" => "Platform",
            "options" => [{ "id" => 5, "value" => "Windows" }, { "id" => 6, "value" => "Mac" }],
            "required" => false,
          },
        ],
      )
    end
  end

  describe "#attach" do
    it "requires user to be signed in" do
      post "/jira/issues/attach.json"
      expect(response.status).to eq(403)
    end

    it "must be enabled" do
      SiteSetting.discourse_jira_enabled = false
      sign_in(admin)

      post "/jira/issues/attach.json"
      expect(response.status).to eq(404)
    end

    it "requires issue key in correct format" do
      sign_in(admin)
      post = Fabricate(:post)

      post "/jira/issues/attach.json",
           params: {
             issue_key: "../DIS/42",
             topic_id: post.topic_id,
             post_number: post.post_number,
           }

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"][0]).to eq(
        I18n.t("invalid_params", message: "issue_key"),
      )
    end

    it "attach an existing Jira issue to post" do
      sign_in(admin)
      post = Fabricate(:post)

      stub_request(:get, "https://example.com/rest/api/2/issue/10041").to_return(
        status: 200,
        body: issue_response,
      )
      stub_request(:get, "https://example.com/rest/api/2/issue/DIS-42").to_return(
        status: 200,
        body: issue_response,
      )

      expect do
        post "/jira/issues/attach.json",
             params: {
               issue_key: "DIS-42",
               topic_id: post.topic_id,
               post_number: post.post_number,
             }
      end.to change { Post.count }.by(1)
      expect(response.parsed_body["issue_key"]).to eq("DIS-42")
      expect(response.parsed_body["issue_url"]).to eq("https://example.com/browse/DIS-42")
      expect(post.reload.custom_fields["jira_issue_key"]).to eq("DIS-42")
      expect(Post.last.post_type).to eq(Post.types[:whisper])
    end
  end

  describe "#webhook" do
    let!(:issue_param) do
      {
        id: "10041",
        key: "DIS-42",
        fields: {
          resolution: {
            name: "Fixed",
          },
          status: {
            name: "Done",
          },
        },
      }
    end

    fab!(:topic)
    fab!(:post2) { Fabricate(:post, topic: topic, post_number: 1) }

    before do
      post2.jira_issue_key = "DIS-42"
      SiteSetting.discourse_jira_webhook_token = "secret"
    end

    it "closes the topic when the issue has resolution" do
      SiteSetting.discourse_jira_close_topic_on_resolve = true
      post "/jira/issues/webhook.json",
           params: {
             t: "secret",
             issue_event_type_name: "issue_generic",
             timestamp: "1536083559131",
             webhookEvent: "jira:issue_updated",
             issue: issue_param,
           }

      expect(topic.reload.closed).to eq(true)
      expect(post2.reload.custom_fields["jira_issue"]).to eq(JSON.parse(issue_param.to_json))
      expect(topic.tags.pluck(:name)).not_to contain_exactly(%w[jira-issue status-done])
    end

    it "adds status tags to the topic when the issue has status" do
      SiteSetting.tagging_enabled = true
      SiteSetting.discourse_jira_issue_tags_enabled = true
      post "/jira/issues/webhook.json",
           params: {
             t: "secret",
             issue_event_type_name: "issue_generic",
             timestamp: "1536083559131",
             webhookEvent: "jira:issue_updated",
             issue: issue_param,
           }

      expect(topic.tags.pluck(:name)).to contain_exactly("jira-issue", "status-done")
    end

    it "creates reply to topic when the issue is commented" do
      SiteSetting.discourse_jira_sync_issue_comments = true

      expect {
        post "/jira/issues/webhook.json",
             params: {
               t: "secret",
               issue_event_type_name: "issue_commented",
               timestamp: "1536083559131",
               webhookEvent: "jira:issue_updated",
               issue: {
                 id: "10041",
                 key: "DIS-42",
               },
               comment: {
                 id: "10041",
                 body: "This is a comment",
               },
             }
      }.to change { topic.reload.posts.count }.by(1)

      expect(topic.posts.last.raw).to eq("This is a comment")
    end
  end
end

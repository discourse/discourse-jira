# frozen_string_literal: true

require "rails_helper"
require "json"
require_relative "../spec_helper"

describe DiscourseJira::IssuesController do
  let(:admin) { Fabricate(:admin) }
  let(:issue_response) do
    '{"expand":"renderedFields,names,schema,operations,editmeta,changelog,versionedRepresentations,customfield_10010.requestTypePractice","id":"10041","self":"https://example.com/rest/api/2/issue/10041","key":"DIS-42","fields":{"statuscategorychangedate":"2022-04-04T21:15:11.247+0300","issuetype":{"self":"https://example.com/rest/api/2/issuetype/10001","id":"10001","description":"Tasks track small, distinct pieces of work.","iconUrl":"https://example.com/rest/api/2/universal_avatar/view/type/issuetype/avatar/10318?size=medium","name":"Task","subtask":false,"avatarId":10318,"entityId":"3c4b5100-26b0-4392-867c-d9aa0a27975f","hierarchyLevel":0},"timespent":null,"project":{"self":"https://example.com/rest/api/2/project/10000","id":"10000","key":"DIS","name":"Discourse","projectTypeKey":"software","simplified":true,"avatarUrls":{"48x48":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400","24x24":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400?size=small","16x16":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400?size=xsmall","32x32":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400?size=medium"}},"fixVersions":[],"aggregatetimespent":null,"resolution":null,"resolutiondate":null,"workratio":-1,"lastViewed":null,"watches":{"self":"https://example.com/rest/api/2/issue/DIS-42/watchers","watchCount":1,"isWatching":true},"issuerestriction":{"issuerestrictions":{},"shouldDisplay":true},"created":"2022-04-04T21:15:10.881+0300","customfield_10020":null,"customfield_10021":null,"customfield_10022":null,"priority":{"self":"https://example.com/rest/api/2/priority/3","iconUrl":"https://example.com/images/icons/priorities/medium.svg","name":"Medium","id":"3"},"customfield_10023":null,"customfield_10024":null,"customfield_10025":null,"labels":[],"customfield_10016":null,"customfield_10017":null,"customfield_10018":{"hasEpicLinkFieldDependency":false,"showField":false,"nonEditableReason":{"reason":"PLUGIN_LICENSE_ERROR","message":"The Parent Link is only available to Jira Premium users."}},"customfield_10019":"0|i0000n:","aggregatetimeoriginalestimate":null,"timeestimate":null,"versions":[],"issuelinks":[],"assignee":null,"updated":"2022-04-04T21:15:10.881+0300","status":{"self":"https://example.com/rest/api/2/status/10000","description":"","iconUrl":"https://example.com/","name":"To Do","id":"10000","statusCategory":{"self":"https://example.com/rest/api/2/statuscategory/2","id":2,"key":"new","colorName":"blue-gray","name":"To Do"}},"components":[],"timeoriginalestimate":null,"description":"Originally from: http://127.0.0.1:4200/t/welcome-to-the-lounge/8\n\n-------------------------\nPost from: system @ 2022-04-04 16:33:17 UTC\n\nCongratulations! :confetti_ball: \nIf you can see this topic, you were recently promoted to regular (trust level 3). \nYou can now … \n\nEdit the title of any topic\nChange the category of any topic\nHave all your links followed (automatic nofollow is removed)\nAccess a private Lounge category only visible to users at trust level 3 and higher\nHide spam with a single flag\n\nHere’s the current list of fellow regulars. Be sure to say hi. \nThanks for being an important part of this community! \n(For more information on trust levels, see this topic. Please note that only members who continue to meet the requirements over time will remain regulars.)","customfield_10010":null,"customfield_10014":null,"customfield_10015":null,"timetracking":{},"customfield_10005":null,"customfield_10006":null,"customfield_10007":null,"security":null,"customfield_10008":null,"attachment":[],"customfield_10009":null,"aggregatetimeestimate":null,"summary":"[Discourse] Welcome to the Lounge","creator":{"self":"https://example.com/rest/api/2/user?accountId=70121%3A40a02bc7-6a81-4445-9b9e-8d49951a4ebd","accountId":"70121:40a02bc7-6a81-4445-9b9e-8d49951a4ebd","emailAddress":"foo@example.com","avatarUrls":{"48x48":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png","24x24":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png","16x16":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png","32x32":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png"},"displayName":"Foo Bar","active":true,"timeZone":"Europe/Bucharest","accountType":"atlassian"},"subtasks":[],"reporter":{"self":"https://example.com/rest/api/2/user?accountId=70121%3A40a02bc7-6a81-4445-9b9e-8d49951a4ebd","accountId":"70121:40a02bc7-6a81-4445-9b9e-8d49951a4ebd","emailAddress":"foo@example.com","avatarUrls":{"48x48":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png","24x24":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png","16x16":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png","32x32":"https://secure.gravatar.com/avatar/93ca0545f57bae0ef29f8545a8389d54?d=https%3A%2F%2Favatar-management--avatars.us-west-2.prod.public.atl-paas.net%2Finitials%2FDU-6.png"},"displayName":"Foo Bar","active":true,"timeZone":"Europe/Bucharest","accountType":"atlassian"},"aggregateprogress":{"progress":0,"total":0},"customfield_10000":"{}","customfield_10001":null,"customfield_10002":null,"customfield_10003":null,"customfield_10004":null,"environment":null,"duedate":null,"progress":{"progress":0,"total":0},"votes":{"self":"https://example.com/rest/api/2/issue/DIS-42/votes","votes":0,"hasVoted":false},"comment":{"comments":[],"self":"https://example.com/rest/api/2/issue/10041/comment","maxResults":0,"total":0,"startAt":0},"worklog":{"startAt":0,"maxResults":20,"total":0,"worklogs":[]}}}'
  end

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
      expect(post.reload.custom_fields["jira_issue_key"]).to eq("DIS-42")
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
    fab!(:topic) { Fabricate(:topic) }
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
             issue: {
               id: "10041",
               key: "DIS-42",
               fields: {
                 resolution: {
                   name: "Fixed",
                 },
               },
             },
           }

      expect(topic.reload.closed).to eq(true)
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

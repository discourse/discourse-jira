# frozen_string_literal: true

require 'rails_helper'

describe DiscourseJira::IssuesController do
  let(:admin) { Fabricate(:admin) }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = 'https://example.com/'
  end

  describe '#preflight' do
    before do
      stub_request(:get, 'https://example.com/rest/api/2/project/search?expand=issueTypes').
        to_return(status: 200, body: '{"self":"https://example.com/rest/api/2/project/search?expand=issueTypes&maxResults=50&startAt=0","maxResults":50,"startAt":0,"total":1,"isLast":true,"values":[{"expand":"description,lead,issueTypes,url,projectKeys,permissions,insight","self":"https://example.com/rest/api/2/project/10000","id":"10000","key":"DIS","issueTypes":[{"self":"https://example.com/rest/api/2/issuetype/10001","id":"10001","description":"Tasks track small, distinct pieces of work.","iconUrl":"https://example.com/rest/api/2/universal_avatar/view/type/issuetype/avatar/10318?size=medium","name":"Task","subtask":false,"avatarId":10318,"hierarchyLevel":0},{"self":"https://example.com/rest/api/2/issuetype/10002","id":"10002","description":"Epics track collections of related bugs, stories, and tasks.","iconUrl":"https://example.com/rest/api/2/universal_avatar/view/type/issuetype/avatar/10307?size=medium","name":"Epic","subtask":false,"avatarId":10307,"hierarchyLevel":1},{"self":"https://example.com/rest/api/2/issuetype/10003","id":"10003","description":"Subtasks track small pieces of work that are part of a larger task.","iconUrl":"https://example.com/rest/api/2/universal_avatar/view/type/issuetype/avatar/10316?size=medium","name":"Subtask","subtask":true,"avatarId":10316,"hierarchyLevel":-1}],"name":"Discourse","avatarUrls":{"48x48":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400","24x24":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400?size=small","16x16":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400?size=xsmall","32x32":"https://example.com/rest/api/2/universal_avatar/view/type/project/avatar/10400?size=medium"},"projectTypeKey":"software","simplified":true,"style":"next-gen","isPrivate":false,"properties":{},"entityId":"ac014fab-6202-4bcc-9fb0-f4a50bc6c0ef","uuid":"ac014fab-6202-4bcc-9fb0-f4a50bc6c0ef"}]}', headers: {})
    end

    it 'should return a list of projects and issue types' do
      sign_in(admin)

      get '/jira/issues/preflight.json'
      expect(response.parsed_body).to eq({
        'email' => admin.email,
        'projects' => [
          {
            'name' => 'Discourse',
            'key' => 'DIS',
            'issue_types' => [
              { 'id' => '10001', 'name' => 'Task' },
              { 'id' => '10002', 'name' => 'Epic' }
            ],
          }
        ],
      })
    end
  end

  describe '#create' do
    it 'requires user to be signed in' do
      post '/jira/issues.json'
      expect(response.status).to eq(403)
    end

    it 'must be enabled' do
      SiteSetting.discourse_jira_enabled = false
      sign_in(admin)

      post '/jira/issues.json'
      expect(response.status).to eq(403)
    end

    it 'create a Jira issue and ' do
      sign_in(admin)
      post = Fabricate(:post)

      stub_request(:post, 'https://example.com/rest/api/2/issue').
        to_return(status: 201, body: '{"id":"10041","key":"DIS-42","self":"https://discoursetest.atlassian.net/rest/api/2/issue/10041"}', headers: {})

      expect do
        post '/jira/issues.json', params: {
          project_key: 'DIS',
          description: 'This is a bug',
          issue_type_id: '10001',
          topic_id: post.topic_id,
          post_number: post.post_number,
        }
      end.to change { Post.count }.by(1)
      expect(response.parsed_body['issue_key']).to eq('DIS-42')
      expect(response.parsed_body['issue_url']).to eq('https://example.com/browse/DIS-42')
      expect(post.reload.custom_fields['jira_issue_key']).to eq('DIS-42')
    end
  end
end

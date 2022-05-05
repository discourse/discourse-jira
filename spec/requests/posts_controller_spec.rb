# frozen_string_literal: true

require 'rails_helper'

describe DiscourseJira::PostsController do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:topic) { Fabricate(:topic) }
  fab!(:first_post) { Fabricate(:post, topic: topic, raw: 'first post') }
  fab!(:second_post) { Fabricate(:post, topic: topic, post_number: 2, raw: 'second post') }
  fab!(:third_post) { Fabricate(:post, topic: topic, post_number: 3, raw: 'third post') }
  fab!(:fourth_post) { Fabricate(:post, topic: topic, post_number: 4, raw: 'fourth post') }

  before do
    SiteSetting.discourse_jira_enabled = true
    Topic.next_post_number(topic.id)
  end

  describe '#formatted_post_history' do
    it 'requires user to be signed in' do
      put '/jira/posts.json', params: { topic_id: topic.id, post_number: topic.posts.count }

      expect(response.status).to eq(403)
    end

    it 'includes selected post history' do
      sign_in(admin)

      put '/jira/posts.json', params: { topic_id: topic.id, post_number: 3 }
      expect(response.parsed_body['formatted_post_history']).to include('first post')
      expect(response.parsed_body['formatted_post_history']).to include('second post')
      expect(response.parsed_body['formatted_post_history']).to include('third post')
      expect(response.parsed_body['formatted_post_history']).not_to include('fourth post')
      expect(response.parsed_body['formatted_post_history']).to include(topic.url)
    end

    it 'excludes deleted posts' do
      sign_in(admin)
      second_post.delete

      put '/jira/posts.json', params: { topic_id: topic.id, post_number: 3 }

      expect(response.parsed_body['formatted_post_history']).to include('first post')
      expect(response.parsed_body['formatted_post_history']).not_to include('second post')
      expect(response.parsed_body['formatted_post_history']).to include('third post')
      expect(response.parsed_body['formatted_post_history']).not_to include('fourth post')
      expect(response.parsed_body['formatted_post_history']).to include(topic.url)
    end
  end
end

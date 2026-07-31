# frozen_string_literal: true

describe DiscourseJira::PostsController do
  fab!(:admin)
  fab!(:jira_allowed_group, :group)
  fab!(:jira_allowed_user) { Fabricate(:user, groups: [jira_allowed_group]) }
  fab!(:other_user, :user)
  fab!(:topic)
  fab!(:first_post) { Fabricate(:post, topic: topic, raw: "first post") }
  fab!(:second_post) { Fabricate(:post, topic: topic, post_number: 2, raw: "second post") }
  fab!(:third_post) { Fabricate(:post, topic: topic, post_number: 3, raw: "third post") }
  fab!(:fourth_post) { Fabricate(:post, topic: topic, post_number: 4, raw: "fourth post") }

  before do
    SiteSetting.discourse_jira_enabled = true
    Topic.next_post_number(topic.id)
    Group.refresh_automatic_groups!
  end

  describe "#formatted_post_history" do
    it "requires user to be signed in" do
      put "/jira/posts.json", params: { topic_id: topic.id, post_number: topic.posts.count }

      expect(response.status).to eq(403)
    end

    it "includes selected post history" do
      sign_in(admin)

      put "/jira/posts.json", params: { topic_id: topic.id, post_number: 3 }
      expect(response.parsed_body["formatted_post_history"]).to include("first post")
      expect(response.parsed_body["formatted_post_history"]).to include("second post")
      expect(response.parsed_body["formatted_post_history"]).to include("third post")
      expect(response.parsed_body["formatted_post_history"]).not_to include("fourth post")
      expect(response.parsed_body["formatted_post_history"]).to include(topic.url)
    end

    it "omits hidden and whisper posts for Jira-allowed users who cannot see them" do
      SiteSetting.discourse_jira_allowed_groups =
        "#{Group::AUTO_GROUPS[:admins]}|#{jira_allowed_group.id}"
      sign_in(jira_allowed_user)

      hidden_post = Fabricate(:post, topic: topic, post_number: 5, raw: "hidden post", hidden: true)
      whisper_post =
        Fabricate(
          :post,
          topic: topic,
          post_number: 6,
          raw: "whisper post",
          post_type: Post.types[:whisper],
          user: other_user,
        )
      Topic.next_post_number(topic.id)

      put "/jira/posts.json", params: { topic_id: topic.id, post_number: whisper_post.post_number }

      expect(response.status).to eq(200)
      post_history = response.parsed_body["formatted_post_history"]
      expect(post_history).to include(first_post.raw)
      expect(post_history).not_to include(hidden_post.raw)
      expect(post_history).not_to include(whisper_post.raw)
    end

    it "excludes deleted posts" do
      sign_in(admin)
      second_post.delete

      put "/jira/posts.json", params: { topic_id: topic.id, post_number: 3 }

      expect(response.parsed_body["formatted_post_history"]).to include("first post")
      expect(response.parsed_body["formatted_post_history"]).not_to include("second post")
      expect(response.parsed_body["formatted_post_history"]).to include("third post")
      expect(response.parsed_body["formatted_post_history"]).not_to include("fourth post")
      expect(response.parsed_body["formatted_post_history"]).to include(topic.url)
    end
  end
end

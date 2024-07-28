# frozen_string_literal: true

RSpec.describe PostActionCreator do
  let!(:post) { Fabricate(:post) }
  let!(:user) { Fabricate(:user) }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.discourse_jira_url = "https://test.atlassian.net"
  end

  describe "#like" do
    it "enqueues the jira_post_liked job" do
      expect { PostActionCreator.like(user, post) }.to change { Jobs::JiraPostLiked.jobs.size }.by(
        1,
      )
    end
  end
end

# frozen_string_literal: true

RSpec.describe "Jira custom category settings'", type: :system do
  fab!(:current_user, :admin)

  before do
    SiteSetting.discourse_jira_enabled = true
    sign_in(current_user)
  end

  it "renders successfully on the category settings section" do
    visit("/new-category")
    find(".edit-category-settings").click

    expect(page).to have_css(
      ".jira-project",
      text: I18n.t("js.discourse_jira.category_setting.project"),
    )
    expect(page).to have_css(
      ".jira-project",
      text: I18n.t("js.discourse_jira.category_setting.issue_type"),
    )
    expect(page).to have_css(
      ".jira-project",
      text: I18n.t("js.discourse_jira.category_setting.num_likes_auto_create_issue"),
    )
  end
end

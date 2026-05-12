# frozen_string_literal: true

RSpec.describe "Jira custom category settings'" do
  fab!(:current_user, :admin)

  let(:category_page) { PageObjects::Pages::Category.new }

  before do
    SiteSetting.discourse_jira_enabled = true
    SiteSetting.enable_simplified_category_creation = true
    sign_in(current_user)
  end

  it "renders successfully on the category settings section" do
    visit("/new-category")

    # When more than one category type is available, the user is shown a card
    # picker; with only one type the picker is skipped. Click the discussion
    # card if it's rendered, otherwise proceed straight to the form.
    card = page.first(".category-type-cards__card.--category-type-discussion", minimum: 0)
    card&.click

    expect(page).to have_content(I18n.t("js.category.create_with_type", typeName: "discussion"))
    category_page.toggle_advanced_settings
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

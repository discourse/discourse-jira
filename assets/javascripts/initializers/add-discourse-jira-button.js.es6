import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";

export default {
  name: "discourse-jira",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    if (siteSettings.discourse_jira_enabled) {
      withPluginApi("0.8.8", (api) => {
        const currentUser = container.lookup("current-user:main");

        api.attachWidgetAction("post", "createIssue", function () {
          const controller = showModal("discourse-jira-create");
          controller.fillDescription(this.model);
        });

        api.addPostMenuButton("jira", () => {
          if (currentUser.can_create_jira_issue) {
            return {
              action: "createIssue",
              icon: "tag",
              className: "create-jira-issue",
              title: "discourse_jira.create_issue",
              label: "discourse_jira.create_issue",
              position: "first",
            };
          }
        });
      });
    }
  },
};

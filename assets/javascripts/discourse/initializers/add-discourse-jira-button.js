import { withPluginApi } from "discourse/lib/plugin-api";
import JiraIssue from "../components/jira-issue";
import JiraMenuButton from "../components/post-menu/jira-menu-button";

export default {
  name: "discourse-jira",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.discourse_jira_enabled) {
      return;
    }

    withPluginApi((api) => {
      customizePost(api);
      customizePostMenu(api);
    });
  },
};

function customizePost(api) {
  api.addTrackedPostProperties("jira_issue");

  api.renderAfterWrapperOutlet("post-content-cooked-html", JiraIssue);
}

function customizePostMenu(api) {
  const currentUser = api.getCurrentUser();

  api.registerValueTransformer(
    "post-menu-buttons",
    ({ value: dag, context: { firstButtonKey } }) => {
      if (!currentUser?.can_create_jira_issue) {
        return;
      }

      dag.add("jira", JiraMenuButton, { before: firstButtonKey });
    }
  );
}

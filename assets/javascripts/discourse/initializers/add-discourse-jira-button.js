import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { iconHTML } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";
import PostCooked from "discourse/widgets/post-cooked";
import AttachModal from "../components/modal/attach";
import CreateModal from "../components/modal/create";
import JiraMenuButton from "../components/post-menu/jira-menu-button";

export default {
  name: "discourse-jira",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.discourse_jira_enabled) {
      return;
    }

    withPluginApi("1.34.0", (api) => {
      customizePostMenu(api);

      api.includePostAttributes("jira_issue");

      api.decorateWidget("post-contents:after-cooked", (helper) => {
        const postModel = helper.getModel();
        if (!postModel || !postModel.jira_issue) {
          return;
        }

        const jira = postModel.jira_issue;

        const jiraUrl = jira.self.replace(
          /\/rest\/api\/.*$/,
          "/browse/" + jira.key
        );

        const cooked = `
            <aside class='quote jira-issue' data-jira-key='${jira.key}'>
              <div class='title'>
                ${iconHTML("tag")}
                <a href='${jiraUrl}'>${jira.fields.summary}</a>
              </div>
              <blockquote>
                <i>(${jira.key})</i>
                <span class='jira-status jira-status-${jira.fields.status.id}'>
                  ${jira.fields.status.name}
                </span>
              </blockquote>
            </aside>
          `;

        const postCooked = new PostCooked({ cooked }, helper);
        return helper.rawHtml(postCooked.init());
      });
    });
  },
};

function customizePostMenu(api) {
  const currentUser = api.getCurrentUser();

  const transformerRegistered = api.registerValueTransformer(
    "post-menu-buttons",
    ({ value: dag, context: { firstButtonKey } }) => {
      if (!currentUser?.can_create_jira_issue) {
        return;
      }

      dag.add("jira", JiraMenuButton, { before: firstButtonKey });
    }
  );

  const silencedKey =
    transformerRegistered && "discourse.post-menu-widget-overrides";

  withSilencedDeprecations(silencedKey, () => customizeWidgetPostMenu(api));
}

function customizeWidgetPostMenu(api) {
  const currentUser = api.container.lookup("service:current-user");
  const modal = api.container.lookup("service:modal");

  api.attachWidgetAction("post", "createIssue", function () {
    modal.show(CreateModal, { model: this.model });
  });

  api.attachWidgetAction("post", "attachIssue", function () {
    modal.show(AttachModal, { model: this.model });
  });

  api.attachWidgetAction("post-menu", "toggleJiraMenu", function () {
    this.state.jiraVisible = !this.state.jiraVisible;
  });

  api.attachWidgetAction("post-menu", "closeJiraMenu", function () {
    this.state.jiraVisible = false;
  });

  api.addPostMenuButton("jira", (attrs) => {
    if (currentUser?.can_create_jira_issue && !attrs.jira_issue) {
      return {
        action: "toggleJiraMenu",
        icon: "fab-jira",
        className: "jira-menu",
        title: "discourse_jira.menu.title",
        position: "first",
      };
    }
  });

  api.decorateWidget("post-menu:before-extra-controls", (helper) => {
    if (!helper.state.jiraVisible) {
      return;
    }

    return helper.attach("post-jira-menu");
  });
}

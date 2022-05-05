import { withPluginApi } from "discourse/lib/plugin-api";
import showModal from "discourse/lib/show-modal";
import PostCooked from "discourse/widgets/post-cooked";
import { iconHTML } from "discourse-common/lib/icon-library";

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

        api.includePostAttributes("jira_issue");

        api.addPostMenuButton("jira", (attrs) => {
          if (currentUser.can_create_jira_issue && !attrs.jira_issue) {
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
                <i>(${jira.key})</i>
                <span class='jira-status jira-status-${jira.fields.status.id}'>
                  ${jira.fields.status.name}
                </span>
              </div>
              <blockquote>
                ${jira.fields.description}
              </blockquote>
            </aside>
          `;

          const postCooked = new PostCooked({ cooked }, helper);
          return helper.rawHtml(postCooked.init());
        });
      });
    }
  },
};

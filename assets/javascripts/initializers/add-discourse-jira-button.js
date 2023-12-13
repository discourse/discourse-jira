import CreateModal from "../discourse/components/modal/create";
import AttachModal from "../discourse/components/modal/attach";
import { withPluginApi } from "discourse/lib/plugin-api";
import PostCooked from "discourse/widgets/post-cooked";
import { iconHTML } from "discourse-common/lib/icon-library";

export default {
  name: "discourse-jira",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    const modal = container.lookup("service:modal");

    if (siteSettings.discourse_jira_enabled) {
      withPluginApi("0.8.8", (api) => {
        const currentUser = container.lookup("service:current-user");

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

        api.includePostAttributes("jira_issue");

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
    }
  },
};

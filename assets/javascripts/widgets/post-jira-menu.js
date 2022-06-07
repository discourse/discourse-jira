import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";

export function buildManageButtons(attrs, currentUser) {
  if (!currentUser) {
    return [];
  }

  let contents = [];
  if (currentUser.staff) {
    contents.push({
      icon: "plus",
      className: "popup-menu-button create-issue",
      label: "discourse_jira.actions.create_issue",
      action: "createIssue",
    });

    contents.push({
      icon: "paperclip",
      className: "popup-menu-button attach-issue",
      label: "discourse_jira.actions.attach_issue",
      action: "attachIssue",
    });
  }

  return contents;
}

export default createWidget("post-jira-menu", {
  tagName: "div.post-jira-menu.post-admin-menu.popup-menu",

  html() {
    const contents = [];

    buildManageButtons(this.attrs, this.currentUser).forEach((b) => {
      b.secondaryAction = "closeJiraMenu";
      contents.push(this.attach("post-admin-menu-button", b));
    });

    return h("ul", contents);
  },

  clickOutside() {
    this.sendWidgetAction("closeJiraMenu");
  },
});

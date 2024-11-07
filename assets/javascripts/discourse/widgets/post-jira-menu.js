import { h } from "virtual-dom";
import { createWidget } from "discourse/widgets/widget";

// TODO (glimmer-post-menu): Remove this widget after the post menu widget code is removed
export function buildManageButtons(attrs, currentUser) {
  if (!currentUser) {
    return [];
  }

  let contents = [];
  if (currentUser.can_create_jira_issue) {
    contents.push({
      icon: "plus",
      className: "popup-menu-button create-issue",
      label: "discourse_jira.menu.create_issue",
      action: "createIssue",
    });

    contents.push({
      icon: "paperclip",
      className: "popup-menu-button attach-issue",
      label: "discourse_jira.menu.attach_issue",
      action: "attachIssue",
    });
  }

  return contents;
}

export default createWidget("post-jira-menu", {
  tagName: "div.post-jira-menu.popup-menu",

  html() {
    const contents = [];

    buildManageButtons(this.attrs, this.currentUser).forEach((b) => {
      b.secondaryAction = "closeJiraMenu";
      contents.push(this.attach("post-jira-menu-button", b));
    });

    return h("ul", contents);
  },

  clickOutside() {
    this.sendWidgetAction("closeJiraMenu");
  },
});

createWidget("post-jira-menu-button", {
  tagName: "li",

  html(attrs) {
    return this.attach("button", {
      className: attrs.className,
      action: attrs.action,
      url: attrs.url,
      icon: attrs.icon,
      label: attrs.label,
      secondaryAction: attrs.secondaryAction,
    });
  },
});

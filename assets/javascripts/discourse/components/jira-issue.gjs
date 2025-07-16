import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";

export default class JiraIssue extends Component {
  static shouldRender(args) {
    return args.post.jira_issue;
  }

  get issue() {
    return this.args.post.jira_issue;
  }

  get url() {
    return this.issue.self.replace(
      /\/rest\/api\/.*$/,
      "/browse/" + this.issue.key
    );
  }

  <template>
    <div class="cooked">
      <aside class="quote jira-issue" data-jira-key={{this.issue.key}}>
        <div class="title">
          {{icon "tag"}}
          <a href={{this.url}}>{{this.issue.fields.summary}}</a>
        </div>
        <blockquote>
          <i>({{this.issue.key}})</i>
          <span
            class={{concatClass
              "jira-status"
              (concat "jira-status-" this.issue.fields.status.id)
            }}
          >
            {{this.issue.fields.status.name}}
          </span>
        </blockquote>
      </aside>
    </div>
  </template>
}

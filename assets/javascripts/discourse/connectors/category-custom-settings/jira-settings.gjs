import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import withEventValue from "discourse/helpers/with-event-value";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { t } from "I18n";
import ComboBox from "select-kit/components/combo-box";

export default class JiraSettings extends Component {
  static shouldRender(args, container) {
    return container.siteSettings.discourse_jira_enabled;
  }

  @tracked loading = false;
  @tracked projects = [];
  @tracked projectId = null;
  @tracked issueTypeId = null;

  constructor() {
    super(...arguments);
    this.preflightChecks();
  }

  get category() {
    return this.args.outletArgs.category;
  }

  get issueTypes() {
    const project = this.projects.findBy("id", this.projectId);
    return project ? project.issue_types : [];
  }

  @action
  onChangeProject(projectId) {
    this.projectId = projectId;
    this.category.custom_fields.jira_project_id = projectId;
  }

  @action
  onChangeIssueType(issueTypeId) {
    this.issueTypeId = issueTypeId;
    this.category.custom_fields.jira_issue_type_id = issueTypeId;
  }

  @action
  async preflightChecks() {
    this.loading = true;
    try {
      const result = await ajax("/jira/issues/preflight");
      if (result.projects) {
        this.projects = result.projects;
        this.projectId = this.category.custom_fields.jira_project_id;
        this.issueTypeId = this.category.custom_fields.jira_issue_type_id;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  <template>
    <div class="jira-settings">
      <h3>{{t "discourse_jira.category_setting.title"}}</h3>
      <section class="field jira-project">
        <label>{{t "discourse_jira.category_setting.project"}}</label>
        <div class="controls">
          <ComboBox
            @name="project_id"
            @content={{this.projects}}
            @valueProperty="id"
            @value={{this.projectId}}
            @onChange={{this.onChangeProject}}
          />
        </div>
      </section>
      <section class="field jira-project">
        <label>{{t "discourse_jira.category_setting.issue_type"}}</label>
        <div class="controls">
          <ComboBox
            @name="issue_type"
            @content={{this.issueTypes}}
            @value={{this.issueTypeId}}
            @onChange={{this.onChangeIssueType}}
          />
        </div>
      </section>
      <section class="field jira-project">
        <label>{{t
            "discourse_jira.category_setting.num_likes_auto_create_issue"
          }}</label>
        <div class="controls">
          <input
            type="number"
            min="1"
            value={{this.category.custom_fields.jira_num_likes_auto_create_issue}}
            {{on
              "input"
              (withEventValue
                (fn
                  (mut
                    this.category.custom_fields.jira_num_likes_auto_create_issue
                  )
                )
              )
            }}
          />
        </div>
      </section>
    </div>
  </template>
}

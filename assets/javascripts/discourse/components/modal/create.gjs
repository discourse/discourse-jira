import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { action } from "@ember/object";
import { TrackedArray, TrackedObject } from "@ember-compat/tracked-built-ins";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import DTextarea from "discourse/components/d-textarea";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import ComboBox from "select-kit/components/combo-box";
import JiraField from "../jira-field";

export default class Create extends Component {
  @tracked loading = false;
  @tracked projects = [];

  @tracked topicId = null;
  @tracked postNumber = null;
  @tracked projectId = null;
  @tracked issueTypeId = null;
  @tracked fields = new TrackedArray([]);
  @tracked title = "";
  @tracked description = "";

  @tracked issueKey = null;
  @tracked issueUrl = null;

  constructor() {
    super(...arguments);
    this.preflightChecks();
    this.fillDescription(this.args.model);
  }

  get issueTypes() {
    const project = this.projects.findBy("id", this.projectId);
    return project ? project.issue_types : [];
  }

  get disabled() {
    return (
      this.loading ||
      !this.projectId ||
      !this.issueTypeId ||
      !this.description ||
      this.requiredFields.filter((f) => !f.value).length
    );
  }

  get descriptionText() {
    return this.topicId
      ? "discourse_jira.create_form.review_description"
      : "discourse_jira.create_form.provide_description";
  }

  get requiredFields() {
    return this.fields.filter((field) => field.required);
  }

  get optionalFields() {
    return this.fields.filter((field) => !field.required);
  }

  @action
  async preflightChecks() {
    this.loading = true;
    try {
      const result = await ajax("/jira/issues/preflight");
      if (result.projects) {
        this.projects = result.projects;
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  async fillDescription(post) {
    this.loading = true;
    try {
      const result = await ajax("/jira/posts", {
        type: "PUT",
        data: { topic_id: post.topic_id, post_number: post.post_number },
      });

      if (result) {
        this.topicId = post.topic_id;
        this.postNumber = post.post_number;
        this.title = post.topic.title;
        this.description = result.formatted_post_history.substring(0, 32767);
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  async createIssue() {
    this.loading = true;
    try {
      const sanitizedFields = this.fields.map(field => {
        return {
          required: field.required,
          value: field.value,
          key: field.key,
          field_type: field.field_type,
        };
      });

      const result = await ajax("/jira/issues", {
        type: "POST",
        data: {
          project_id: this.projectId,
          issue_type_id: this.issueTypeId,
          title: this.title,
          description: this.description,
          topic_id: this.topicId,
          post_number: this.postNumber,
          fields: sanitizedFields,
        },
      });

      this.issueKey = result.issue_key;
      this.issueUrl = result.issue_url;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  onChangeProject(projectId) {
    this.projectId = projectId;
  }

  @action
  onChangeIssueType(issueTypeId) {
    this.issueTypeId = issueTypeId;
    this.fetchFields();
  }

  fetchFields() {
    this.loading = true;
    ajax("/jira/issue/createmeta", {
      type: "GET",
      data: { project_id: this.projectId, issue_type_id: this.issueTypeId },
    })
      .then((result) => {
        if (result.fields) {
          this.fields = result.fields.map((field) => new TrackedObject(field));
        }
      })
      .catch(popupAjaxError)
      .finally(() => (this.loading = false));
  }

  <template>
    <DModal
      @title={{i18n "discourse_jira.attach_issue"}}
      @closeModal={{@closeModal}}
    >
      <:body>
        {{#if this.issueKey}}
          <p>{{i18n
              "discourse_jira.issue_creation_success"
              issueKey=this.issueKey
            }}</p>
          <p><a href={{this.issueUrl}}>{{this.issueKey}}</a></p>
        {{else}}
          <div class="create-issue form">
            <section class="field">
              <section class="field-item project">
                <label>{{i18n "discourse_jira.create_form.project"}}</label>
                <ComboBox
                  @name="project_id"
                  @content={{this.projects}}
                  @valueProperty="id"
                  @value={{this.projectId}}
                  @onChange={{this.onChangeProject}}
                />
              </section>

              <section class="field-item issue-type">
                <label>{{i18n "discourse_jira.create_form.issue_type"}}</label>
                <ComboBox
                  @name="issue_type"
                  @content={{this.issueTypes}}
                  @value={{this.issueTypeId}}
                  @onChange={{this.onChangeIssueType}}
                />
              </section>
            </section>

            <section class="field">
              <label>{{i18n "discourse_jira.create_form.title"}}</label>
              <Input
                @value={{this.title}}
                class="jira-title"
                autofocus="autofocus"
              />
            </section>

            <section class="field">
              <label>{{i18n "discourse_jira.create_form.description"}}</label>
              <DTextarea
                @value={{this.description}}
                class="jira-description"
                autofocus="autofocus"
                @maxlength="32767"
              />
            </section>

            <div class="required-fields">
              {{#each this.requiredFields as |field|}}
                <JiraField @field={{field}} />
              {{/each}}
            </div>

            {{#if this.optionalFields}}
              <details class="optional-fields">
                <summary>Optional Fields</summary>
                {{#each this.optionalFields as |field|}}
                  <JiraField @field={{field}} />
                {{/each}}
              </details>
            {{/if}}
          </div>
        {{/if}}

      </:body>
      <:footer>
        {{#if this.issueKey}}
          <DButton
            class="btn-primary"
            @action={{@closeModal}}
            @label="discourse_jira.create_form.continue"
          />
        {{else}}
          <DButton
            class="btn-primary"
            @action={{this.createIssue}}
            @label="discourse_jira.create_issue"
            @disabled={{this.disabled}}
            @isLoading={{this.loading}}
          />
        {{/if}}
      </:footer>
    </DModal>
  </template>
}

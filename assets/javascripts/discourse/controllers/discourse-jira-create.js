import Controller from "@ember/controller";
import { action } from "@ember/object";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  loading: false,

  projects: null,

  topicId: null,
  postNumber: null,
  projectKey: null,
  issueTypeId: null,
  title: "",
  description: "",

  issueKey: null,
  issueUrl: null,

  onShow() {
    this.setProperties({
      loading: false,
      projects: [],
      topicId: null,
      postNumber: null,
      projectKey: null,
      issueTypeId: null,
      fields: [],
      title: "",
      description: "",
      issueKey: null,
      issueUrl: null,
    });

    this.preflightChecks();
  },

  preflightChecks() {
    this.set("loading", true);
    ajax("/jira/issues/preflight", {})
      .then((result) => {
        if (result.projects) {
          this.set("projects", result.projects);
        }
      })
      .catch(popupAjaxError)
      .finally(() => this.set("loading", false));
  },

  fillDescription(post) {
    this.set("loading", true);

    ajax("/jira/posts", {
      type: "PUT",
      data: { topic_id: post.topic_id, post_number: post.post_number },
    })
      .then((result) => {
        if (result) {
          this.setProperties({
            topicId: post.topic_id,
            postNumber: post.post_number,
            title: post.topic.title,
            description: result.formatted_post_history.substring(0, 32767),
          });
        }
      })
      .catch(popupAjaxError)
      .finally(() => this.set("loading", false));
  },

  @discourseComputed("projects", "projectKey")
  issueTypes(projects, projectKey) {
    const project = projects.findBy("key", projectKey);
    return project ? project.issue_types : [];
  },

  @discourseComputed(
    "loading",
    "projectKey",
    "issueTypeId",
    "description",
    "requiredFields.@each.value"
  )
  disabled(loading, projectKey, issueTypeId, description) {
    return (
      loading ||
      !projectKey ||
      !issueTypeId ||
      !description ||
      this.requiredFields.filter((f) => !f.value).length
    );
  },

  @discourseComputed("topicId")
  descriptionText() {
    return this.topicId
      ? "discourse_jira.create_form.review_description"
      : "discourse_jira.create_form.provide_description";
  },

  @discourseComputed("fields")
  requiredFields(fields) {
    return fields.filter((field) => field.required);
  },

  @discourseComputed("fields")
  optionalFields(fields) {
    return fields.filter((field) => !field.required);
  },

  @observes("issueTypeId")
  getFields() {
    this.set("loading", true);
    ajax(`/jira/issues/${this.issueTypeId}/fields`, {})
      .then((result) => {
        if (result.fields) {
          this.set("fields", result.fields);
        }
      })
      .catch(popupAjaxError)
      .finally(() => this.set("loading", false));
  },

  @action
  createIssue() {
    this.set("loading", true);

    ajax("/jira/issues", {
      type: "POST",
      data: {
        project_key: this.projectKey,
        issue_type_id: this.issueTypeId,
        title: this.title,
        description: this.description,
        topic_id: this.topicId,
        post_number: this.postNumber,
        fields: this.fields,
      },
    })
      .then((result) => {
        this.setProperties({
          issueKey: result.issue_key,
          issueUrl: result.issue_url,
        });
      })
      .catch(popupAjaxError)
      .finally(() => this.set("loading", false));
  },

  @action
  cancel() {
    this.send("closeModal");
  },
});

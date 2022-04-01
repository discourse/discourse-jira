import Controller from "@ember/controller";
import { action } from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  requestedFor: "",
  description: "",
  createdFromPost: null,

  loading: false,
  createdIssue: null,
  preflightError: null,

  onShow() {
    this.setProperties({
      createdIssue: null,
      description: "",
      loading: false,
      projects: [],
    });

    this.preflightChecks();
  },

  preflightChecks() {
    this.set("loading", true);
    ajax("/discourse-jira/issues/preflight", {})
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

    ajax("/discourse-jira/posts", {
      type: "PUT",
      data: { topic_id: post.topic_id, post_number: post.post_number },
    })
      .then((result) => {
        if (result) {
          this.setProperties({
            topicId: post.topic_id,
            postNumber: post.post_number,
            title: post.topic.title,
            description: result.formatted_post_history,
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

  @discourseComputed("loading", "projectKey", "issueTypeId", "description")
  disabled(loading, projectKey, issueTypeId, description) {
    return loading || !projectKey || !issueTypeId || !description;
  },

  @discourseComputed("topicId")
  descriptionText() {
    return this.topicId
      ? "discourse_jira.create_form.review_description"
      : "discourse_jira.create_form.provide_description";
  },

  @action
  createIssue() {
    this.set("loading", true);

    ajax("/discourse-jira/issues", {
      type: "POST",
      data: {
        project_key: this.projectKey,
        issue_type_id: this.issueTypeId,
        description: this.description,
        topic_id: this.topicId,
        post_number: this.postNumber,
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

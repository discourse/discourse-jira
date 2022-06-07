import Controller from "@ember/controller";
import { action } from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Controller.extend(ModalFunctionality, {
  loading: false,

  topicId: null,
  postNumber: null,
  issueKey: null,
  issueUrl: null,

  onShow() {
    this.setProperties({
      loading: false,
      topicId: null,
      postNumber: null,
      issueKey: null,
      issueUrl: null,
    });
  },

  fillDescription(post) {
    this.setProperties({
      topicId: post.topic_id,
      postNumber: post.post_number,
    });
  },

  @discourseComputed("loading", "issueKey")
  disabled(loading, issueKey) {
    return loading || !issueKey;
  },

  @action
  attachIssue() {
    this.set("loading", true);

    ajax("/jira/issues/attach", {
      type: "POST",
      data: {
        issue_key: this.issueKey,
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

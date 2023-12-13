import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import i18n from "discourse-common/helpers/i18n";
import { Input } from "@ember/component";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class Attach extends Component {
  @tracked loading = false;
  @tracked issueKey = null;
  @tracked issueUrl = null;

  topicId = this.args.model.topic_id;
  postNumber = this.args.model.post_number;

  get disabled() {
    return this.loading || !this.issueKey;
  }

  @action
  async attachIssue() {
    try {
      this.loading = true;
      const result = await ajax("/jira/issues/attach", {
        type: "POST",
        data: {
          issue_key: this.issueKey,
          topic_id: this.topicId,
          post_number: this.postNumber,
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

  <template>
    <DModal
      @title={{i18n "discourse_jira.attach_issue"}}
      @closeModal={{@closeModal}}
    >
      <:body>
        {{#if this.issueUrl}}
          <p>
            {{i18n
              "discourse_jira.issue_creation_success"
              issueKey=this.issueKey
            }}
          </p>
          <p><a href={{this.issueUrl}}>{{this.issueKey}}</a></p>
        {{else}}
          <div class="form">
            <section class="field">
              <section class="field-item">
                <label>{{i18n "discourse_jira.attach_form.issue_key"}}</label>
                <Input
                  @value={{this.issueKey}}
                  class="jira-key"
                  autofocus="autofocus"
                />
              </section>
            </section>
          </div>
        {{/if}}
      </:body>
      <:footer>
        {{#if this.issueUrl}}
          <DButton
            class="btn-primary"
            @action={{@closeModal}}
            @label="discourse_jira.attach_form.continue"
          />
        {{else}}
          <DButton
            class="btn-primary"
            @action={{this.attachIssue}}
            @label="discourse_jira.attach_issue"
            @disabled={{this.disabled}}
            @isLoading={{this.loading}}
          />
        {{/if}}
      </:footer>
    </DModal>
  </template>
}

import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import i18n from "discourse-common/helpers/i18n";
import DMenu from "float-kit/components/d-menu";
import AttachModal from "../modal/attach";
import CreateModal from "../modal/create";

export default class JiraMenuButton extends Component {
  static shouldRender(args) {
    return !args.post.jira_issue;
  }

  @service modal;

  @action
  attachIssue() {
    this.modal.show(AttachModal, { model: this.args.post });
  }

  @action
  createIssue() {
    this.modal.show(CreateModal, { model: this.args.post });
  }

  // TODO (glimmer-post-menu): When updating the template below do not forget to update the menu widget
  <template>
    <DMenu
      class="post-action-menu__jira-menu jira-menu"
      ...attributes
      @autofocus={{true}}
      @identifier="post-jira-menu"
      @icon="fab-jira"
      @modalForMobile={{true}}
      @title={{i18n "discourse_jira.menu.title"}}
    >
      <DropdownMenu as |dropdown|>
        <dropdown.item>
          <DButton
            class="post-action-menu__jira-create-issue create-issue btn-transparent"
            @action={{this.createIssue}}
            @icon="plus"
            @label="discourse_jira.menu.create_issue"
          />
        </dropdown.item>
        <dropdown.item>
          <DButton
            class="post-action-menu__jira-attach-issue attach-issue btn-transparent"
            @action={{this.attachIssue}}
            @icon="paperclip"
            @label="discourse_jira.menu.attach_issue"
          />
        </dropdown.item>
      </DropdownMenu>
    </DMenu>
  </template>
}

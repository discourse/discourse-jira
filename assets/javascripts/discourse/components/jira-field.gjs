import Component from "@glimmer/component";
import JiraFieldDate from "./fields/dj-date-field";
import JiraFieldDropdown from "./fields/dj-dropdown-field";
import JiraFieldMultiselect from "./fields/dj-multiselect-field";
import JiraFieldText from "./fields/dj-text-field";
import JiraFieldTextArea from "./fields/dj-textarea-field";

export default class JiraField extends Component {
  get component() {
    switch (this.args.field.field_type) {
      case "string":
        const textAreaFields = ["description", "summary"];
        if (textAreaFields.includes(this.args.field.key)) {
          return JiraFieldTextArea;
        }

        return JiraFieldText;
      case "array":
        return JiraFieldMultiselect;
      case "option":
        return JiraFieldDropdown;
      case "date":
        return JiraFieldDate;
      default:
        return JiraFieldText;
    }
  }

  <template>
    <this.component
      @field={{@field}}
      @saveIssue={{@saveIssue}}
      @label={{@field.name}}
    />
  </template>
}

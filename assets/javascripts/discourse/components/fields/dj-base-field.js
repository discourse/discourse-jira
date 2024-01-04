import Component from "@ember/component";

export default class BaseField extends Component {
  tagName = "";
  field = null;
  label = null;
  saveIssue = null;
}

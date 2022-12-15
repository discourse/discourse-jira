import { computed } from "@ember/object";
import BaseField from "./dj-base-field";

export default class MultiselectField extends BaseField {
  @computed("field.options.[]")
  get replacedContent() {
    return (this.field.options || []).map((o) => {
      return {
        id: o.id,
        name: o.value,
      };
    });
  }
}

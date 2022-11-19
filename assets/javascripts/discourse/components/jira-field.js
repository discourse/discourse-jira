import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  tagName: "",
  field: null,
  saveIssue: null,

  @discourseComputed("field.key", "field.field_type")
  component(key, field_type) {
    switch (field_type) {
      case "string":
        if (key === "summary" || key === "description") {
          return "textarea";
        }

        return "text";
      default:
        return field_type;
    }
  },
});

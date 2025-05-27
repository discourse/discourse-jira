import { computed } from "@ember/object";
import MultiSelect from "select-kit/components/multi-select";
import BaseField from "./dj-base-field";
import fieldsDjFieldLabel from "./dj-field-label";

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

  <template>
    <div class="field control-group">
      {{fieldsDjFieldLabel label=this.label field=this.field}}

      <div class="controls">
        <MultiSelect
          @content={{this.replacedContent}}
          @value={{this.field.value}}
          @onChange={{action (mut this.field.value)}}
        />
      </div>
    </div>
  </template>
}

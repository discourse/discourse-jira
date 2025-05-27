import { hash } from "@ember/helper";
import { computed } from "@ember/object";
import comboBox from "select-kit/components/combo-box";
import BaseField from "./dj-base-field";
import fieldsDjFieldLabel from "./dj-field-label";

export default class DropdownField extends BaseField {
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
        {{comboBox
          value=this.field.value
          content=this.replacedContent
          onChange=(action (mut this.field.value))
          options=(hash allowAny=false disabled=this.field.isDisabled)
        }}
      </div>
    </div>
  </template>
}

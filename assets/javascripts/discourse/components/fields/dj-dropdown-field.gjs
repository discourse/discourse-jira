import { hash } from "@ember/helper";
import { computed } from "@ember/object";
import ComboBox from "select-kit/components/combo-box";
import BaseField from "./dj-base-field";
import FieldsDjFieldLabel from "./dj-field-label";

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
      <FieldsDjFieldLabel @label={{this.label}} @field={{this.field}} />

      <div class="controls">
        <ComboBox @value={{this.field.value}} @content={{this.replacedContent}} @onChange={{action (mut this.field.value)}} @options={{hash allowAny=false disabled=this.field.isDisabled}} />
      </div>
    </div>
  </template>
}

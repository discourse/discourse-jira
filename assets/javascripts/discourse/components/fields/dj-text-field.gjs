import { Input } from "@ember/component";
import BaseField from "./dj-base-field";
import fieldsDjFieldLabel from "./dj-field-label";

export default class TextField extends BaseField {
  <template>
    <section class="field text-field">
      <div class="control-group">
        {{fieldsDjFieldLabel label=this.label field=this.field}}

        <div class="controls">
          <div class="field-wrapper">
            {{Input
              value=this.field.value
              required=this.field.required
              input=(action (mut this.field.value) value="target.value")
            }}
          </div>
        </div>
      </div>
    </section>
  </template>
}

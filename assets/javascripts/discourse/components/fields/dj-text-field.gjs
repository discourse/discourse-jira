import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import withEventValue from "discourse/helpers/with-event-value";
import BaseField from "./dj-base-field";
import FieldsDjFieldLabel from "./dj-field-label";

export default class TextField extends BaseField {
  <template>
    <section class="field text-field">
      <div class="control-group">
        <FieldsDjFieldLabel @label={{this.label}} @field={{this.field}} />

        <div class="controls">
          <div class="field-wrapper">
            <Input
              {{on "input" (withEventValue (fn (mut this.field.value)))}}
              @value={{this.field.value}}
              @required={{this.field.required}}
            />
          </div>
        </div>
      </div>
    </section>
  </template>
}

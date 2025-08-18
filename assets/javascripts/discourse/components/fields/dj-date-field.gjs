import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action, computed } from "@ember/object";
import DButton from "discourse/components/d-button";
import withEventValue from "discourse/helpers/with-event-value";
import BaseField from "./dj-base-field";
import FieldsDjFieldLabel from "./dj-field-label";

export default class DateField extends BaseField {
  @action
  convertToUniversalTime(date) {
    return date && this.set("field.value", moment(date).utc().format());
  }

  @computed("field.metadata.value")
  get localTime() {
    return (
      this.field.value &&
      moment(this.field.value).local().format(moment.HTML5_FMT.DATETIME_LOCAL)
    );
  }

  <template>
    <section class="field date-field">
      <div class="control-group">
        <FieldsDjFieldLabel @label={{this.label}} @field={{this.field}} />

        <div class="controls">
          <div class="controls-row">
            <Input
              {{on "input" (withEventValue this.convertToUniversalTime)}}
              @value={{readonly this.localTime}}
              @type="date"
            />

            {{#if this.field.value}}
              <DButton
                @icon="trash-alt"
                @action={{fn (mut this.field.value) null}}
              />
            {{/if}}
          </div>
        </div>
      </div>
    </section>
  </template>
}

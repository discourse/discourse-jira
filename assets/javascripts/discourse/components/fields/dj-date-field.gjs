import { Input } from "@ember/component";
import { action, computed } from "@ember/object";
import DButton from "discourse/components/d-button";
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
            {{Input
              type="date"
              value=(readonly this.localTime)
              input=(action "convertToUniversalTime" value="target.value")
            }}

            {{#if this.field.value}}
              <DButton
                @icon="trash-alt"
                @action={{action (mut this.field.value) value=null}}
              />
            {{/if}}
          </div>
        </div>
      </div>
    </section>
  </template>
}

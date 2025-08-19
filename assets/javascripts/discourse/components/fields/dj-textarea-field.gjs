import { fn } from "@ember/helper";
import DTextarea from "discourse/components/d-textarea";
import withEventValue from "discourse/helpers/with-event-value";
import FieldsDjFieldLabel from "./dj-field-label";

const DjTextareaField = <template>
  <section class="field text-field">
    <div class="control-group">
      <FieldsDjFieldLabel @label={{this.label}} @field={{this.field}} />

      <div class="controls">
        <div class="field-wrapper">
          <DTextarea
            @value={{this.field.metadata.value}}
            @input={{withEventValue (fn (mut this.field.metadata.value))}}
          />
        </div>
      </div>
    </div>
  </section>
</template>;

export default DjTextareaField;

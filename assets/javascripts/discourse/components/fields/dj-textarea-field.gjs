import DTextarea from "discourse/components/d-textarea";
import FieldsDjFieldLabel from "./dj-field-label";

const DjTextareaField = <template>
  <section class="field text-field">
    <div class="control-group">
      <FieldsDjFieldLabel @label={{this.label}} @field={{this.field}} />

      <div class="controls">
        <div class="field-wrapper">
          <DTextarea @value={{this.field.metadata.value}} @input={{action (mut this.field.metadata.value) value="target.value"}} />
        </div>
      </div>
    </div>
  </section>
</template>;

export default DjTextareaField;

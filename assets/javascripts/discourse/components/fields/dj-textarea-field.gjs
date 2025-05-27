import dTextarea from "discourse/components/d-textarea";
import fieldsDjFieldLabel from "./dj-field-label";

const DjTextareaField = <template>
  <section class="field text-field">
    <div class="control-group">
      {{fieldsDjFieldLabel label=this.label field=this.field}}

      <div class="controls">
        <div class="field-wrapper">
          {{dTextarea
            value=this.field.metadata.value
            input=(action (mut this.field.metadata.value) value="target.value")
          }}
        </div>
      </div>
    </div>
  </section>
</template>;

export default DjTextareaField;

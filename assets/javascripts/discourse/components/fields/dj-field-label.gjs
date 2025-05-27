import Component from "@ember/component";

export default class FieldLabel extends Component {
  field = null;
  label = null;

  <template>
    {{#if this.label}}
      <label class="control-label">
        <span>
          {{this.label}}
          {{#if this.field.required}}
            *
          {{/if}}
        </span>
      </label>
    {{/if}}
  </template>
}

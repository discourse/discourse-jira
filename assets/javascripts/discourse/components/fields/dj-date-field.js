import { action, computed } from "@ember/object";
import BaseField from "./dj-base-field";

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
}

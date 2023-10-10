import { Controller } from "@hotwired/stimulus";
import { enter, leave } from "el-transition";

export default class extends Controller {
  static targets = ["notification"];
  static minY = 64;

  connect() {
    enter(this.element);
  }

  close(event) {
    event.preventDefault();
    leave(this.element).then(() => {
      this.element.remove();
    });
  }
}

import { Controller } from "stimulus"
import { leave } from "el-transition";

export default class extends Controller {
  hide() {
    leave(this.element)
  }
}

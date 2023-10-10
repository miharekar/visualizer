import { Controller } from "@hotwired/stimulus";
import { enter, leave } from "el-transition";

export default class extends Controller {
  static targets = ["notification"];
  static minY = 64;

  connect() {
    this.scrollHandler = this.handleScroll.bind(this);
    window.addEventListener("scroll", this.scrollHandler);
    document.addEventListener("turbo:load", this.scrollHandler);
    this.notificationTargets.forEach((element) => {
      enter(element);
    });
  }

  disconnect() {
    window.removeEventListener("scroll", this.scrollHandler);
    document.removeEventListener("turbo:load", this.scrollHandler);
  }

  handleScroll() {
    const scrollY = window.scrollY;
    const notification = this.element;

    notification.classList.remove("sm:top-16");

    if (scrollY < this.constructor.minY) {
      notification.style.top = `${this.constructor.minY - scrollY}px`;
      notification.classList.remove("sm:top-4");
    } else {
      notification.style.top = "0px";
      notification.classList.add("sm:top-4");
    }
  }

  close(event) {
    const element = this.notificationTargets.find((notificationTarget) =>
      notificationTarget.contains(event.currentTarget)
    );
    if (element) {
      leave(element).then(() => {
        element.remove();
      });
    }
  }
}

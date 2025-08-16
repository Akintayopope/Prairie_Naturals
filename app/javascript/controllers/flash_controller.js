import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { timeout: { type: Number, default: 4000 } }

  connect() {
    this._timer = setTimeout(() => this.dismiss(), this.timeoutValue);
    // also clear flash on navigation so it doesn't linger with Turbo
    document.addEventListener("turbo:before-visit", this._dismissBeforeVisit);
  }

  disconnect() {
    clearTimeout(this._timer);
    document.removeEventListener("turbo:before-visit", this._dismissBeforeVisit);
  }

  dismiss = () => {
    if (!this.element) return;
    this.element.style.transition = "opacity .25s ease";
    this.element.style.opacity = "0";
    this.element.addEventListener("transitionend", () => this.element?.remove(), { once: true });
  };

  _dismissBeforeVisit = () => this.dismiss();
}

import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

export default class TlProgressBar extends Component {
  get fillWidth() {
    return htmlSafe(`width: ${Math.min(this.args.percentage, 100)}%`);
  }

  get barClass() {
    if (this.args.percentage >= 100) {
      return "tl-progress-bar__fill --complete";
    }
    if (this.args.variant === "warning") {
      return "tl-progress-bar__fill --warning";
    }
    return "tl-progress-bar__fill";
  }

  <template>
    <div class="tl-progress-bar">
      <div class="tl-progress-bar__track">
        <div class={{this.barClass}} style={{this.fillWidth}}></div>
      </div>
      {{#if @label}}
        <span class="tl-progress-bar__label">{{@label}}</span>
      {{/if}}
    </div>
  </template>
}

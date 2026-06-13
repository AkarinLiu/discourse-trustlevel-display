import Component from "@glimmer/component";
import { service } from "@ember/service";
import TlProgressBar from "./tl-progress-bar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class TlProgressSummary extends Component {
  @service siteSettings;


  get progress() {
    // Support both direct @progress and @outletArgs (from renderInOutlet)
    return this.args.progress || this.args.outletArgs?.model?.tl_progress;
  }

  get showProgress() {
    return this.progress && this.siteSettings.trustlevel_display_enabled;
  }

  get currentLevelName() {
    return this.levelName(this.progress.trust_level);
  }

  get nextLevelName() {
    if (this.progress.is_tl4) {
      return this.levelName(4);
    }
    return this.levelName(this.progress.next_level);
  }

  get progressPercent() {
    return this.progress?.overall_progress_percent ?? 0;
  }

  get progressLabel() {
    return `${this.progressPercent}%`;
  }

  levelName(level) {
    const keys = ["newuser", "basic", "member", "regular", "leader"];
    return i18n(`trustlevel_display.level_names.${keys[level] || "newuser"}`);
  }

  <template>
    {{#if this.showProgress}}
      <li class="stats-tl-progress">
        <div class="tl-progress-summary">
          {{#if this.progress.is_tl4}}
            <div class="tl-progress-summary__tl4">
              {{dIcon "circle-check"}}
              <span>{{i18n "trustlevel_display.tl4_status"}}</span>
            </div>
          {{else if this.progress.downgrade_risk}}
            <div class="tl-progress-summary__risk">
              {{dIcon "triangle-exclamation"}}
              <span>{{i18n "trustlevel_display.downgrade_risk_warning"}}</span>
            </div>
          {{else}}
            <div class="tl-progress-summary__levels">
              <span class="tl-progress-summary__current">{{this.currentLevelName}}</span>
              <span class="tl-progress-summary__arrow">→</span>
              <span class="tl-progress-summary__next">{{this.nextLevelName}}</span>
            </div>
            <TlProgressBar @percentage={{this.progressPercent}} @label={{this.progressLabel}} />
          {{/if}}
        </div>
      </li>
    {{/if}}
  </template>
}

import Component from "@glimmer/component";
import { service } from "@ember/service";
import TlProgressBar from "./tl-progress-bar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class TlProgressSummaryCard extends Component {
  @service siteSettings;


  get progress() {
    return this.args.outletArgs?.user?.tl_progress;
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
      <div class="tl-progress-card">
        {{#if this.progress.is_tl4}}
          <div class="tl-progress-card__tl4">
            {{dIcon "circle-check"}}
            <span>{{this.currentLevelName}}</span>
          </div>
        {{else if this.progress.downgrade_risk}}
          <div class="tl-progress-card__risk">
            {{dIcon "triangle-exclamation"}}
            <span>{{i18n "trustlevel_display.downgrade_risk_warning"}}</span>
          </div>
        {{else}}
          <div class="tl-progress-card__bar">
            <TlProgressBar @percentage={{this.progressPercent}} />
          </div>
          <div class="tl-progress-card__levels">
            <span>{{this.currentLevelName}}</span>
            <span class="tl-progress-card__arrow">→</span>
            <span>{{this.nextLevelName}}</span>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import TlProgressBar from "../../components/tl-progress-bar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class UserTrustLevelDisplay extends Component {
  @service siteSettings;


  @tracked showDetails = false;

  get model() {
    return this.args.model;
  }

  get user() {
    return this.args.controller?.user || this.args.model;
  }

  get currentLevelName() {
    return this.levelName(this.model.trust_level);
  }

  get nextLevelName() {
    if (this.model.is_tl4) {
      return this.levelName(4);
    }
    return this.levelName(this.model.next_level);
  }

  get pageTitle() {
    return i18n("trustlevel_display.progress_page_title", {
      username: this.user.username,
    });
  }

  get overallProgressLabel() {
    return `${this.model.overall_progress_percent}%`;
  }

  get toggleButtonLabel() {
    return this.showDetails
      ? i18n("trustlevel_display.hide_requirements")
      : i18n("trustlevel_display.requirements_title");
  }

  levelName(level) {
    const keys = ["newuser", "basic", "member", "regular", "leader"];
    return i18n(`trustlevel_display.level_names.${keys[level] || "newuser"}`);
  }

  metricLabel(name) {
    return i18n(`trustlevel_display.metrics.${name}`);
  }

  @action
  toggleDetails() {
    this.showDetails = !this.showDetails;
  }

  <template>
    <div class="tl-display-page">
      <h2 class="tl-display-page__title">{{this.pageTitle}}</h2>

      {{#if this.model.is_tl4}}
        <div class="tl-display-page__tl4-notice">
          <span class="tl-display-page__tl4-icon">{{dIcon "circle-check"}}</span>
          <p>{{i18n "trustlevel_display.tl4_status"}}</p>
        </div>
      {{else}}
        {{#if this.model.downgrade_risk}}
          <div class="tl-display-page__risk-banner">
            {{dIcon "triangle-exclamation"}}
            <span>{{i18n "trustlevel_display.downgrade_risk_warning"}}</span>
          </div>
        {{/if}}

        <div class="tl-display-page__header">
          <div class="tl-display-page__level-info">
            <div class="tl-display-page__current-level">
              <span class="tl-display-page__level-label">{{i18n "trustlevel_display.current_level"}}</span>
              <span class="tl-display-page__level-badge">{{this.currentLevelName}}</span>
            </div>
            <div class="tl-display-page__arrow">→</div>
            <div class="tl-display-page__next-level">
              <span class="tl-display-page__level-label">{{i18n "trustlevel_display.next_level"}}</span>
              <span class="tl-display-page__level-badge">{{this.nextLevelName}}</span>
            </div>
          </div>
        </div>

        <div class="tl-display-page__overall">
          <h3>{{i18n "trustlevel_display.overall_progress"}}</h3>
          <TlProgressBar
            @percentage={{this.model.overall_progress_percent}}
            @label={{this.overallProgressLabel}}
          />
        </div>

        {{#if this.model.requirements}}
          <button
            class="btn btn-default tl-display-page__toggle"
            type="button"
            {{on "click" this.toggleDetails}}
          >
            {{this.toggleButtonLabel}}
          </button>

          {{#if this.showDetails}}
            <div class="tl-display-page__details">
              {{#each this.model.requirements as |req|}}
                <div class="tl-display-page__requirement">
                  <div class="tl-display-page__requirement-header">
                    <span class="tl-display-page__requirement-name">
                      {{this.metricLabel req.name}}
                    </span>
                    <span class="tl-display-page__requirement-values">
                      {{req.current}}
                      /
                      {{req.required}}
                      {{#if req.at_risk}}
                        <span class="tl-display-page__requirement-status --at-risk">
                          {{i18n "trustlevel_display.requirement_at_risk"}}
                        </span>
                      {{else if req.met}}
                        <span class="tl-display-page__requirement-status --met">
                          {{i18n "trustlevel_display.requirement_met"}}
                        </span>
                      {{else}}
                        <span class="tl-display-page__requirement-status --pending">
                          {{i18n "trustlevel_display.requirement_pending"}}
                        </span>
                      {{/if}}
                    </span>
                  </div>
                  <TlProgressBar
                    @percentage={{req.percentage}}
                    @variant={{if req.at_risk "warning" "default"}}
                  />
                </div>
              {{/each}}
            </div>
          {{/if}}
        {{/if}}
      {{/if}}
    </div>
  </template>
}

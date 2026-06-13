# frozen_string_literal: true

# name: discourse-trustlevel-display
# about: Displays trust level upgrade progress and downgrade risk for Discourse users
# meta_topic_id: TODO
# version: 0.1.0
# authors: AkarinLiu
# url: https://github.com/AkarinLiu/discourse-trustlevel-display
# required_version: 2.7.0
# license: MIT

enabled_site_setting :trustlevel_display_enabled

Discourse::Application.routes.append do
  get "u/:username/trustlevel" => "users#show",
      :constraints => { username: RouteFormat.username }
end

module ::TrustLevelDisplay
  PLUGIN_NAME = "discourse-trustlevel-display"
end

require_relative "lib/trust_level_display/engine"

register_asset "stylesheets/common/trustlevel-display.scss"
register_asset "stylesheets/mobile/trustlevel-display.scss"

after_initialize do
  add_to_serializer(:user_summary, :tl_progress) do
    return nil unless SiteSetting.trustlevel_display_enabled
    return nil if SiteSetting.trustlevel_display_visibility == "only_self" && scope.user != object.user && !scope.is_staff?
    progress = TrustLevelDisplay::TrustLevelProgress.new(object.user)
    progress.progress_summary
  end

  add_to_serializer(:user_card, :tl_progress) do
    return nil unless SiteSetting.trustlevel_display_enabled
    return nil unless scope.user
    return nil if SiteSetting.trustlevel_display_visibility == "only_self" && scope.user != object && !scope.is_staff?
    progress = TrustLevelDisplay::TrustLevelProgress.new(object)
    progress.progress_summary
  end

  add_to_serializer(:user, :tl_progress) do
    return nil unless SiteSetting.trustlevel_display_enabled
    return nil if SiteSetting.trustlevel_display_visibility == "only_self" && scope.user != object && !scope.is_staff?
    progress = TrustLevelDisplay::TrustLevelProgress.new(object)
    progress.progress_summary
  end
end

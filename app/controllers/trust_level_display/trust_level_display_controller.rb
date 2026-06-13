# frozen_string_literal: true

module ::TrustLevelDisplay
  class TrustLevelDisplayController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_logged_in

    def show
      user = User.find_by(username: params[:username])
      raise Discourse::NotFound unless user

      guardian.ensure_can_see_profile!(user)

      # Check visibility setting: only_self means only the profile owner or staff can view
      if SiteSetting.trustlevel_display_visibility == "only_self" && current_user != user && !guardian.is_staff?
        raise Discourse::InvalidAccess
      end

      progress = TrustLevelProgress.new(user)

      result = progress.progress_summary

      # Only return full requirements for the current user or staff
      if current_user == user || guardian.is_staff?
        result[:requirements] = progress.requirements
      end

      render json: result
    end
  end
end

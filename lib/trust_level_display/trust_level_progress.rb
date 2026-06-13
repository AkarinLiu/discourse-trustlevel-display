# frozen_string_literal: true

module ::TrustLevelDisplay
  class TrustLevelProgress
    def initialize(user)
      @user = user
    end

    # Lightweight summary for serializer extensions — no extra DB queries for TL0-TL2
    def progress_summary
      {
        trust_level: trust_level,
        next_level: next_level,
        is_tl4: is_tl4,
        overall_progress_percent: overall_progress_percent,
        downgrade_risk: downgrade_risk,
      }
    end

    # Full requirements list — used by the controller endpoint
    def requirements
      return [] if is_tl4

      case next_level
      when 1
        tl1_requirements
      when 2
        tl2_requirements
      when 3
        tl3_downgrade_check
      else
        []
      end
    end

    def trust_level
      @user.trust_level
    end

    def next_level
      return nil if trust_level >= TrustLevel[4]
      trust_level + 1
    end

    def is_tl4
      trust_level >= TrustLevel[4]
    end

    def overall_progress_percent
      return 100 if is_tl4

      reqs = requirements
      return 0 if reqs.empty?

      (reqs.sum { |r| r[:percentage] } / reqs.size.to_f).round
    end

    # TL3-specific: check if any metric is below the 90% low-water mark
    def downgrade_risk
      return false unless trust_level == TrustLevel[3]

      reqs = tl3_downgrade_check
      return false if reqs.empty?

      reqs.any? { |r| r[:at_risk] }
    end

    private

    def stat
      @user.user_stat
    end

    def account_age_minutes
      ((Time.now - @user.created_at) / 60).to_i
    end

    # === TL1 requirements ===

    def tl1_requirements
      [
        requirement_metric("topics_entered", stat.topics_entered, SiteSetting.tl1_requires_topics_entered),
        requirement_metric("posts_read", stat.posts_read_count, SiteSetting.tl1_requires_read_posts),
        requirement_metric("time_read", stat.time_read / 60, SiteSetting.tl1_requires_time_spent_mins),
        requirement_metric("account_age", account_age_minutes, SiteSetting.tl1_requires_time_spent_mins),
      ]
    end

    # === TL2 requirements ===

    # TL2 thresholds are higher than TL1, so overlapping metrics use TL2 settings.
    def tl2_requirements
      [
        requirement_metric("topics_entered", stat.topics_entered, SiteSetting.tl2_requires_topics_entered),
        requirement_metric("posts_read", stat.posts_read_count, SiteSetting.tl2_requires_read_posts),
        requirement_metric("time_read", stat.time_read / 60, SiteSetting.tl2_requires_time_spent_mins),
        requirement_metric("account_age", account_age_minutes, SiteSetting.tl2_requires_time_spent_mins),
        requirement_metric("days_visited", stat.days_visited, SiteSetting.tl2_requires_days_visited),
        requirement_metric("likes_received", stat.likes_received, SiteSetting.tl2_requires_likes_received),
        requirement_metric("likes_given", stat.likes_given, SiteSetting.tl2_requires_likes_given),
        requirement_metric("topic_reply_count", stat.calc_topic_reply_count!, SiteSetting.tl2_requires_topic_reply_count),
      ]
    end

    # === TL3 downgrade risk check ===

    def tl3_requirements_obj
      @tl3_reqs ||= TrustLevel3Requirements.new(@user)
    end

    LOW_WATER_MARK = 0.9

    def tl3_downgrade_check
      tl3 = tl3_requirements_obj

      [
        downgrade_metric("days_visited", tl3.days_visited, tl3.min_days_visited),
        downgrade_metric("topics_replied_to", tl3.num_topics_replied_to, tl3.min_topics_replied_to),
        downgrade_metric("topics_viewed", tl3.topics_viewed, tl3.min_topics_viewed),
        downgrade_metric("posts_read", tl3.posts_read, tl3.min_posts_read),
        flagged_metric("num_flagged_posts", tl3.num_flagged_posts, tl3.max_flagged_posts),
        flagged_metric("num_flagged_by_users", tl3.num_flagged_by_users, tl3.max_flagged_by_users),
        downgrade_metric("topics_viewed_all_time", tl3.topics_viewed_all_time, tl3.min_topics_viewed_all_time),
        downgrade_metric("posts_read_all_time", tl3.posts_read_all_time, tl3.min_posts_read_all_time),
        downgrade_metric("likes_given", tl3.num_likes_given, tl3.min_likes_given),
        downgrade_metric("likes_received", tl3.num_likes_received, tl3.min_likes_received),
        downgrade_metric("likes_received_users", tl3.num_likes_received_users, tl3.min_likes_received_users),
        downgrade_metric("likes_received_days", tl3.num_likes_received_days, tl3.min_likes_received_days),
      ]
    end

    # === Metric helpers ===

    # Standard requirement metric: higher is better
    def requirement_metric(name, current, required)
      percentage = required > 0 ? [(current.to_f / required * 100).round, 100].min : 100
      {
        name: name,
        current: current,
        required: required,
        percentage: percentage,
        met: current >= required,
      }
    end

    # TL3 downgrade metric: shows risk (below 90% low-water mark)
    def downgrade_metric(name, current, required)
      percentage = required > 0 ? [(current.to_f / required * 100).round, 100].min : 100
      {
        name: name,
        current: current,
        required: required,
        percentage: percentage,
        met: current >= required,
        at_risk: current < (required * LOW_WATER_MARK),
      }
    end

    # Flagged posts metric: lower is better (reverse logic)
    def flagged_metric(name, current, max_allowed)
      met = current <= max_allowed
      # For flagged metrics, "progress" is 100% when at or below the max
      percentage = max_allowed > 0 ? [(max_allowed - current).to_f / max_allowed * 100, 0].max.round : 100
      {
        name: name,
        current: current,
        required: max_allowed,
        percentage: percentage,
        met: met,
        at_risk: !met,
      }
    end
  end
end

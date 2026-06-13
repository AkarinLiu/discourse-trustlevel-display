# frozen_string_literal: true

require "rails_helper"

describe TrustLevelDisplay::TrustLevelProgress do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[0]) }

  before do
    SiteSetting.tl1_requires_topics_entered = 5
    SiteSetting.tl1_requires_read_posts = 30
    SiteSetting.tl1_requires_time_spent_mins = 10
    SiteSetting.tl2_requires_topics_entered = 20
    SiteSetting.tl2_requires_read_posts = 100
    SiteSetting.tl2_requires_time_spent_mins = 60
    SiteSetting.tl2_requires_days_visited = 15
    SiteSetting.tl2_requires_likes_received = 1
    SiteSetting.tl2_requires_likes_given = 1
    SiteSetting.tl2_requires_topic_reply_count = 3
  end

  describe "#trust_level" do
    it "returns the user's trust level" do
      progress = described_class.new(user)
      expect(progress.trust_level).to eq(0)
    end
  end

  describe "#next_level" do
    it "returns 1 for TL0 user" do
      progress = described_class.new(user)
      expect(progress.next_level).to eq(1)
    end

    it "returns nil for TL4 user" do
      user.update!(trust_level: TrustLevel[4])
      progress = described_class.new(user)
      expect(progress.next_level).to be_nil
    end
  end

  describe "#is_tl4" do
    it "returns false for non-TL4 user" do
      progress = described_class.new(user)
      expect(progress.is_tl4).to be false
    end

    it "returns true for TL4 user" do
      user.update!(trust_level: TrustLevel[4])
      progress = described_class.new(user)
      expect(progress.is_tl4).to be true
    end
  end

  describe "#progress_summary" do
    it "includes trust_level, next_level, is_tl4, overall_progress_percent, downgrade_risk" do
      progress = described_class.new(user)
      summary = progress.progress_summary
      expect(summary.keys).to contain_exactly(
        :trust_level, :next_level, :is_tl4, :overall_progress_percent, :downgrade_risk
      )
    end

    it "returns downgrade_risk: false for non-TL3 users" do
      progress = described_class.new(user)
      expect(progress.progress_summary[:downgrade_risk]).to be false
    end
  end

  describe "#overall_progress_percent" do
    it "returns 100 for TL4 user" do
      user.update!(trust_level: TrustLevel[4])
      progress = described_class.new(user)
      expect(progress.overall_progress_percent).to eq(100)
    end

    it "returns 0 when no requirements are met" do
      progress = described_class.new(user)
      expect(progress.overall_progress_percent).to eq(0)
    end

    it "returns correct progress when partially meeting TL1 requirements" do
      user.user_stat.update!(
        topics_entered: 3,
        posts_read_count: 15,
        time_read: 300 # 5 minutes
      )
      progress = described_class.new(user)
      # metrics: topics_entered(3/5=60), posts_read(15/30=50), time_read(5/10=50), account_age varies
      # Account age is based on created_at so it will be small. Average should be > 0.
      expect(progress.overall_progress_percent).to be > 0
      expect(progress.overall_progress_percent).to be < 50
    end
  end

  describe "#requirements for TL0" do
    it "returns 4 requirements for TL0 user (including account_age)" do
      progress = described_class.new(user)
      reqs = progress.requirements
      expect(reqs.size).to eq(4)
      expect(reqs.map { |r| r[:name] }).to include("account_age")
    end

    it "caps percentage at 100" do
      user.user_stat.update!(
        topics_entered: 100,
        posts_read_count: 500,
        time_read: 6000 # 100 minutes
      )
      progress = described_class.new(user)
      reqs = progress.requirements
      reqs.each { |r| expect(r[:percentage]).to be <= 100 }
    end
  end

  describe "#requirements for TL1" do
    before { user.update!(trust_level: TrustLevel[1]) }

    it "returns 8 requirements for TL1 user" do
      progress = described_class.new(user)
      reqs = progress.requirements
      expect(reqs.size).to eq(8)
    end

    it "includes TL2-specific metrics" do
      progress = described_class.new(user)
      names = progress.requirements.map { |r| r[:name] }
      expect(names).to include("days_visited", "likes_received", "likes_given", "topic_reply_count")
    end
  end

  describe "#requirements for TL4" do
    it "returns empty array for TL4 user" do
      user.update!(trust_level: TrustLevel[4])
      progress = described_class.new(user)
      expect(progress.requirements).to be_empty
    end
  end

  describe "#downgrade_risk for TL3" do
    before { user.update!(trust_level: TrustLevel[3]) }

    it "returns false for non-TL3 users" do
      user.update!(trust_level: TrustLevel[0])
      progress = described_class.new(user)
      expect(progress.downgrade_risk).to be false
    end

    it "returns a boolean for TL3 users" do
      progress = described_class.new(user)
      expect([true, false]).to include(progress.downgrade_risk)
    end
  end
end

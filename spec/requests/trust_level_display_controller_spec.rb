# frozen_string_literal: true

require "rails_helper"

describe TrustLevelDisplay::TrustLevelDisplayController do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[0]) }
  fab!(:other_user) { Fabricate(:user, trust_level: TrustLevel[1]) }
  fab!(:admin) { Fabricate(:admin) }

  before do
    SiteSetting.trustlevel_display_enabled = true
    SiteSetting.trustlevel_display_visibility = "everyone"
  end

  describe "GET #show" do
    it "returns trust level progress for the current user" do
      sign_in(user)
      get "/trustlevel/progress/#{user.username}.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["trust_level"]).to eq(0)
      expect(json["next_level"]).to eq(1)
      expect(json["is_tl4"]).to be false
      expect(json).to have_key("overall_progress_percent")
      expect(json).to have_key("requirements")
    end

    it "returns 404 for non-existent user" do
      sign_in(user)
      get "/trustlevel/progress/nonexistent.json"
      expect(response.status).to eq(404)
    end

    it "returns progress for another user but without requirements" do
      sign_in(user)
      get "/trustlevel/progress/#{other_user.username}.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["trust_level"]).to eq(1)
      expect(json).not_to have_key("requirements")
    end

    it "returns requirements when admin views another user" do
      sign_in(admin)
      get "/trustlevel/progress/#{user.username}.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json).to have_key("requirements")
    end

    it "returns requirements when user views themselves" do
      sign_in(user)
      get "/trustlevel/progress/#{user.username}.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json).to have_key("requirements")
    end

    it "redirects when not logged in" do
      get "/trustlevel/progress/#{user.username}.json"
      expect(response.status).to eq(403)
    end

    it "works for TL4 user" do
      user.update!(trust_level: TrustLevel[4])
      sign_in(user)
      get "/trustlevel/progress/#{user.username}.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json["is_tl4"]).to be true
      expect(json["overall_progress_percent"]).to eq(100)
    end

    it "includes downgrade_risk in the summary" do
      sign_in(user)
      get "/trustlevel/progress/#{user.username}.json"
      expect(response.status).to eq(200)

      json = response.parsed_body
      expect(json).to have_key("downgrade_risk")
    end

    context "with visibility set to only_self" do
      before { SiteSetting.trustlevel_display_visibility = "only_self" }

      it "allows user to view their own progress" do
        sign_in(user)
        get "/trustlevel/progress/#{user.username}.json"
        expect(response.status).to eq(200)
      end

      it "allows admin to view another user's progress" do
        sign_in(admin)
        get "/trustlevel/progress/#{user.username}.json"
        expect(response.status).to eq(200)
      end

      it "denies access when user views another user's progress" do
        sign_in(user)
        get "/trustlevel/progress/#{other_user.username}.json"
        expect(response.status).to eq(403)
      end
    end

    context "with visibility set to everyone" do
      before { SiteSetting.trustlevel_display_visibility = "everyone" }

      it "allows user to view another user's progress" do
        sign_in(user)
        get "/trustlevel/progress/#{other_user.username}.json"
        expect(response.status).to eq(200)
      end
    end
  end
end

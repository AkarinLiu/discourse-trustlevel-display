# frozen_string_literal: true

TrustLevelDisplay::Engine.routes.draw do
  get "/progress/:username" => "trust_level_display#show"
end

Discourse::Application.routes.draw { mount ::TrustLevelDisplay::Engine, at: "/trustlevel" }

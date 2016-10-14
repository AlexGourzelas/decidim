# frozen_string_literal: true

Decidim::Core::Engine.routes.draw do
  devise_for :users,
             class_name: "Decidim::User",
             module: :devise,
             router_name: :decidim,
             controllers: {
               invitations: "decidim/devise/invitations",
               sessions: "decidim/devise/sessions",
               confirmations: "decidim/devise/confirmations",
               registrations: "decidim/devise/registrations",
               passwords: "decidim/devise/passwords"
             }
  resource :locale, only: [:create]
  get "/pages/*id" => "pages#show", as: :page, format: false

  root to: "pages#show", id: "home"
end

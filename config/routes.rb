Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users

  root to: 'home#index'
  get 'webhook/facebook', :to => 'webhook#get_facebook'
  post 'webhook/facebook', :to => 'webhook#post_facebook'

end

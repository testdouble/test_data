Rails.application.routes.draw do
  resources :boops

  root "boops#index"
end

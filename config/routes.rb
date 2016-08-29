Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :payment_channels do
    post :new_key, on: :collection
  end

end

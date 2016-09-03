Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :payment_channels do
    member do
      post :new_key
      post :sign_refund_tx
    end
  end

end

Rails.application.routes.draw do
  resources :licenses
  resources :producers
  resources :salesmen
  resources :states

  get 'update_salesman_report/:id' => 'salesmen#update_salesman_report', as: :update_salesman_report

  root to: 'salesmen#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

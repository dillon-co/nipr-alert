Rails.application.routes.draw do
  devise_for :admins
  resources :stag_adp_employeeinfos
  resources :adp_employees
  resources :licenses
  resources :producers
  resources :salesmen
  resources :states

  # patch 'update_npn_and_licensing_info/:salemsman_id' => 'salesmen#update_npn_and_licensing_info', as: :update_npn_and_licensing_info
  patch 'update_npn_and_licensing_info/:id' => 'salesmen#update_npn_and_licensing_info', as: :update_npn_and_licensing_info
  patch 'xlsheet_data' => 'salesmen#xlsheet_data', as: :xlsheet_data

  get 'update_salesman_report/:id' => 'salesmen#update_salesman_report', as: :update_salesman_report
  get 'find_agent' => 'salesmen#find_agent', as: :find_agent
  get 'agent/:npn' => 'salesmen#agent', as: :agent
  get 'agent/:search_array' => 'salesmen#agent_search', as: :agent_search

  # get 'adp_employees' => 'salesmen#adp_employees', as: :adp_employees

  root to: 'salesmen#find_agent'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

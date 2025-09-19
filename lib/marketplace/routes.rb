Rails.application.routes.draw do
   get "install/download_logs" => 'servers#download_logs'
   get "install/applications_status" => 'servers#applications_status'
   post "install/restart_applications" => 'servers#restart_applications'
   post "install/verify_db_connection" => 'installations#verify_db_connection'
   post "install/init_database" => 'installations#init_database'
   post "install/verify_internet_connection" => 'installations#verify_internet_connection' 
   post "install/send_test_email" => 'installations#send_test_email'
   post "install/set_network_config" => 'installations#set_network_config'
   post "install/register_organisation" => 'installations#register_organisation'
   get "install/initiate_upgrade" => 'installations#initiate_upgrade'
   get "install/update_ssl" => "installations#update_ssl"
   post "install/update_proxy_vars" => "installations#update_proxy_vars"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
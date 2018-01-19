Rails.application.routes.draw do
    root to: 'twitter#mentions'

  get 'twitter/mentions'

  post 'twitter/button' => 'twitter#button'

  post 'twitter/search'
  get 'twitter/search'

  #get 'twitter/reflesh'
  post 'twitter/reflesh'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

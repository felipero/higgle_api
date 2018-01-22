Higgler::API::Router.instance.draw do
  get '/products/', :index, ProductAPI
  get '/product/:id', :show, ProductAPI
  get '/products/liked', :liked, ProductAPI
  post '/products/:product_id/like', :like, ProductAPI
  delete '/products/:product_id/dislike', :dislike, ProductAPI

  post '/higgle/', :create, HiggleAPI
  get '/login', :login, HiggleAPI # we need to remove the login from HiggleAPI - attention to mobile implications
  get '/higgles', :index, HiggleAPI
  get '/higgles_created_by_user', :higgles_created_by_user, HiggleAPI
  get '/for_category', :for_category, HiggleAPI
  get '/for_group', :for_group, HiggleAPI
  post '/higgle/:higgle_id', :join, HiggleAPI

  get '/counter_offer', :show, CounterOfferAPI
  put '/counter_offer/accept', :accept, CounterOfferAPI
  delete '/counter_offer/decline', :decline, CounterOfferAPI

  get '/categories/', :index, CategoryAPI
  put '/category/follow', :follow, CategoryAPI
  put '/category/unfollow', :unfollow, CategoryAPI

  get '/groups/', :index, GroupAPI
  put '/groups/:group_id/join', :join, GroupAPI
  put '/groups/:group_id/leave', :leave, GroupAPI

  get '/users/:user_id/show', :show, UserAPI
  get '/users/:email/find_by_email', :find_by_email, UserAPI
end

Rails.application.routes.draw do
  get "health_reports/index"
  get "users/index"
  get "login/index"

  # 登录相关路由
  get "login", to: "login#index", as: :login
  post "login/send_code", to: "login#send_code"
  post "login/verify_code", to: "login#verify_code"
  post "login/authenticate", to: "login#authenticate"
  delete "logout", to: "login#logout", as: :logout

  # 健康报告相关接口
  get "health_reports", to: "health_reports#index"
  get "health_reports/:id", to: "health_reports#show"
  post "health_reports/update_profile", to: "health_reports#update_profile"
  post "health_reports/upload_avatar", to: "health_reports#upload_avatar"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # 用户管理路由 - 完整的 RESTful 路由
  resources :users

  # 健康档案路由
  get "health_report" => "health_reports#index", as: :health_report 

  # Defines the root path route ("/")
  root to:"login#index"
end
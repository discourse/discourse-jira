# frozen_string_literal: true

DiscourseJira::Engine.routes.draw do
  get '/issues/preflight' => 'issues#preflight'
  post '/issues' => 'issues#create'
  post '/issues/webhook' => 'issues#webhook'
  put '/posts' => 'posts#formatted_post_history'
end

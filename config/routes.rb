# frozen_string_literal: true

DiscourseJira::Engine.routes.draw do
  get '/issues/preflight' => 'issues#preflight'
  get '/issues/:issue_type_id/fields' => 'issues#fields'
  post '/issues' => 'issues#create'
  post '/issues/attach' => 'issues#attach'
  post '/issues/webhook' => 'issues#webhook'
  put '/posts' => 'posts#formatted_post_history'
end

# frozen_string_literal: true

module DiscourseJira
  class Engine < ::Rails::Engine
    engine_name 'DiscourseJira'.freeze
    isolate_namespace DiscourseJira

    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::DiscourseJira::Engine, at: '/jira'
      end
    end
  end
end

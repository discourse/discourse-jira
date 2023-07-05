# frozen_string_literal: true

module DiscourseJira
  PLUGIN_NAME = "discourse-jira"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseJira

    config.after_initialize do
      Discourse::Application.routes.append { mount ::DiscourseJira::Engine, at: "/jira" }
    end
  end
end

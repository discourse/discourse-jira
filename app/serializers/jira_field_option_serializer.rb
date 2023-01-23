# frozen_string_literal: true

class JiraFieldOptionSerializer < ApplicationSerializer
  attributes :id, :value

  def id
    object.jira_id
  end
end

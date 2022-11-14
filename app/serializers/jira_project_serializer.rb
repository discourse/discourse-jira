# frozen_string_literal: true

class JiraProjectSerializer < ApplicationSerializer
  attributes :id,
             :key,
             :name

  has_many :issue_types, serializer: JiraIssueTypeSerializer, embed: :objects
end

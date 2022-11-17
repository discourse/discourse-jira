# frozen_string_literal: true

class JiraFieldSerializer < ApplicationSerializer
  attributes :key,
             :name,
             :required,
             :field_type
end

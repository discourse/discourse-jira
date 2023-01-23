# frozen_string_literal: true

class JiraFieldSerializer < ApplicationSerializer
  attributes :key, :name, :required, :field_type

  has_many :field_options, serializer: JiraFieldOptionSerializer, embed: :objects, key: "options"

  def field_options
    object.options
  end

  def include_field_options?
    object.options.present?
  end
end

# frozen_string_literal: true

class AddFieldOptionIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :jira_field_options, :field_id, name: :index_jira_field_options_on_field_id
    add_index :jira_field_options, :jira_id, name: :index_jira_field_options_on_jira_id
    add_index :jira_field_options,
              %i[field_id jira_id],
              unique: true,
              name: :index_jira_field_options_on_field_id_and_jira_id
  end
end

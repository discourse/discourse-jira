# frozen_string_literal: true

class AddColumnsToFieldsTable < ActiveRecord::Migration[6.0]
  def change
    add_column :jira_fields, :custom, :boolean, null: false, default: false
    add_column :jira_fields, :discourse_field, :boolean, null: false, default: false
  end
end

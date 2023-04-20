# frozen_string_literal: true

class AddSyncedAtColumn < ActiveRecord::Migration[7.0]
  def change
    add_column :jira_projects, :synced_at, :datetime, null: true
    add_column :jira_issue_types, :synced_at, :datetime, null: true
  end
end

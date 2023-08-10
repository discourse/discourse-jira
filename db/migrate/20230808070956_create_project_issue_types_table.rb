# frozen_string_literal: true

class CreateProjectIssueTypesTable < ActiveRecord::Migration[7.0]
  def change
    create_table :jira_project_issue_types do |t|
      t.integer :project_id, null: false
      t.integer :issue_type_id, null: false
      t.timestamps

      t.index %i[project_id issue_type_id], unique: true
    end
  end
end

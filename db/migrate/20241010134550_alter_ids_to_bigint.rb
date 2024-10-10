# frozen_string_literal: true

class AlterIdsToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :jira_project_issue_types, :project_id, :bigint
    change_column :jira_project_issue_types, :issue_type_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

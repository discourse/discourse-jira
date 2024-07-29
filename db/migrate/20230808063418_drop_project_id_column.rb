# frozen_string_literal: true

require "migration/column_dropper"

class DropProjectIdColumn < ActiveRecord::Migration[7.0]
  DROPPED_COLUMNS ||= { jira_issue_types: %i[project_id] }

  def up
    DB.exec "TRUNCATE TABLE jira_issue_types CASCADE;"
    DROPPED_COLUMNS.each { |table, columns| Migration::ColumnDropper.execute_drop(table, columns) }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

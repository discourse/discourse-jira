# frozen_string_literal: true

require "migration/column_dropper"

class DropIssueTypeIdColumn < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  DROPPED_COLUMNS = { jira_fields: %i[issue_type_id required] }

  def up
    execute <<~SQL
      TRUNCATE TABLE jira_fields CASCADE
    SQL

    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS index_jira_fields_on_issue_type_id_and_key
    SQL

    DROPPED_COLUMNS.each { |table, columns| Migration::ColumnDropper.execute_drop(table, columns) }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

# frozen_string_literal: true

class CreateJiraFieldsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :jira_fields do |t|
      t.integer :issue_type_id, null: false
      t.string :key, null: false
      t.string :name, null: false
      t.string :field_type, null: false
      t.boolean :required, null: false, default: false
      t.timestamps

      t.index [:issue_type_id, :key], unique: true
    end
  end
end

# frozen_string_literal: true

class CreateJiraFieldOptionsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :jira_field_options do |t|
      t.integer :field_id, null: false
      t.string :jira_id, null: false, unique: true
      t.string :value, null: false
      t.timestamps
    end
  end
end

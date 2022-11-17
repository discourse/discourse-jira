# frozen_string_literal: true

class CreateJiraTables < ActiveRecord::Migration[6.0]
  def change
    create_table :jira_projects do |t|
      t.integer :uid, null: false, index: true, unique: true
      t.string :key, null: false
      t.string :name
      t.timestamps
    end

    create_table :jira_issue_types do |t|
      t.integer :uid, null: false, index: true, unique: true
      t.integer :project_id, null: false
      t.string :name, null: false
      t.timestamps
    end
  end
end

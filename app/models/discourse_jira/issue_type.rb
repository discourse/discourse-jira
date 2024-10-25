# frozen_string_literal: true

module DiscourseJira
  class IssueType < ::ActiveRecord::Base
    self.table_name = "jira_issue_types"

    # TODO (vinothkannans): use `HasDeprecatedColumns` concern  on 1 September 2023
    self.ignored_columns = ["project_id"]

    has_many :project_issue_types, dependent: :destroy
    has_many :projects, through: :project_issue_types

    def self.sync!
      json_response = Api.getJSON("issuetype")
      return if (json_response.is_a?(Hash) && json_response.has_key?(:error))

      json_response.each do |data|
        next if data[:subtask]
        find_or_initialize_by(uid: data[:id]).tap do |i|
          i.name = data[:name]
          i.save!
        end
      end
    end
  end
end

# == Schema Information
#
# Table name: jira_issue_types
#
#  id         :bigint           not null, primary key
#  uid        :integer          not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  synced_at  :datetime
#
# Indexes
#
#  index_jira_issue_types_on_uid  (uid)
#

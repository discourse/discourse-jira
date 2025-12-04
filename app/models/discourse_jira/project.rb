# frozen_string_literal: true

module DiscourseJira
  class Project < ::ActiveRecord::Base
    self.table_name = "jira_projects"

    has_many :project_issue_types, dependent: :destroy
    has_many :issue_types, through: :project_issue_types

    def sync_issue_types!(data)
      self.name = data[:name]
      self.key = data[:key]

      if data[:issueTypes].present?
        issue_type_uids = data[:issueTypes].filter { |it| !it[:subtask] }.map { |it| it[:id].to_i }
        self.issue_types.where.not(uid: issue_type_uids).destroy_all

        issue_type_uids -= self.issue_types.pluck(:uid)
        self.issue_types.push(IssueType.where(uid: issue_type_uids))
      else
        self.issue_types.destroy_all
      end

      self.synced_at = Time.zone.now
      save!
    end

    def enqueue_sync_job
      delay = rand(0..::Jobs::SyncJira::INTERVAL.to_i)
      ::Jobs.enqueue_in(delay, :sync_jira_project, project_uid: self.uid)
    end

    def self.sync!
      json_response = Api.getJSON("project?expand=issueTypes")
      return if (json_response.is_a?(Hash) && json_response.has_key?(:error))

      json_response.each do |data|
        project = find_or_initialize_by(uid: data[:id])

        if data[:issueTypes].blank?
          project.enqueue_sync_job
        else
          project.sync_issue_types!(data)
        end
      end
    end
  end
end

# == Schema Information
#
# Table name: jira_projects
#
#  id         :bigint           not null, primary key
#  uid        :integer          not null
#  key        :string           not null
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  synced_at  :datetime
#
# Indexes
#
#  index_jira_projects_on_uid  (uid)
#

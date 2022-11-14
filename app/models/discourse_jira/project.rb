# frozen_string_literal: true

module DiscourseJira
  class Project < ::ActiveRecord::Base
    self.table_name = "jira_projects"

    has_many :issue_types, dependent: :destroy

    def sync_issue_types(issue_types)
      issue_types.each do |json|
        next if json[:subtask]

        issue_type = self.issue_types.find_or_create_by(uid: json[:id]) do |i|
          i.name = json[:name]
        end
        issue_type.sync_fields(json[:fields])
      end
    end

    def self.sync!
      return unless SiteSetting.discourse_jira_enabled

      response = Api.get('issue/createmeta?expand=projects.issuetypes.fields')

      projects = JSON.parse(response.body, symbolize_names: true)[:projects]
      projects.each do |json|
        project = find_or_create_by(uid: json[:id]) do |p|
          p.name = json[:name]
          p.key = json[:key]
        end
        project.sync_issue_types(json[:issuetypes])
      end
    end
  end
end

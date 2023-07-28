# frozen_string_literal: true

module Helpers
  def get_jira_response(filename)
    FileUtils.mkdir_p("#{Rails.root}/tmp/spec") unless Dir.exist?("#{Rails.root}/tmp/spec")
    FileUtils.cp(
      "#{Rails.root}/plugins/discourse-jira/spec/fixtures/#{filename}",
      "#{Rails.root}/tmp/spec/#{filename}",
    )
    File.new("#{Rails.root}/tmp/spec/#{filename}").read
  end
end

RSpec.configure { |config| config.include Helpers }

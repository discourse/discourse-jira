# frozen_string_literal: true

module Helpers
  def get_jira_response(filename)
    File.new("#{Rails.root}/plugins/discourse-jira/spec/fixtures/#{filename}").read
  end
end

RSpec.configure { |config| config.include Helpers }

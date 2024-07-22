# Discourse Jira plugin

## Features

- Jira projects, issue types, fields and field options will be synced automatically.
- Create a new Jira issue for a Discourse post with the dynamic issue creation form.
- Attach an existing Jira issue to a Discourse post.
- Sync the status of Jira issue using the webhooks.

## Configuration

Set the values for site settings below before enabling the plugin.

- discourse_jira_url: Put the URL of your Jira instance. It should end with `/` symbol.
- discourse_jira_username: The username of the user whose behalf of going to create issues.
- discourse_jira_password: The API key that assigned to the user who creates issues. A password might work but is unsafe and the API was deprecated by Atlassian.
- discourse_jira_enabled: Enable the Jira plugin for Discourse.
- discourse_jira_allowed_groups: Select the groups you want to allow to use this plugin (defaults to Admins).

### Webhook

Set a secret token to verify the incoming webhooks from Jira.

- discourse_jira_webhook_token: This token must be passed in the 't' query parameter of the webhook. For example: https://discourse.example.com/jira/issues/webhook?t=supersecret

### Debugging

discourse_jira_verbose_log: Enable this setting to log the payloads of both the incoming webhooks and outgoing API requests.

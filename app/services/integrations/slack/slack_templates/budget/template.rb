# frozen_string_literal: true

# Dynamic templates collection slack budget notifications.
class Integrations::Slack::SlackTemplates::Budget::Template
  def self.account_budget_limit_crossed(info, header='')
    { 'text': header,
      'blocks':
        [
          {
            'type': 'header',
            'text': {
              'type': 'plain_text',
              'text': header,
              'emoji': true
            }
          },
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text': "You requested that we alert you when the *cost* associated with your budget *exceeds #{info[:currency]} #{info[:max_amount]}* for the current month.\n\nThe current *cost* for your cloud account linked with CloudStreet is *#{info[:currency]} #{info[:cost_to_date]}*."
            }
          },
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text': "*Name:*  #{info[:budget_name]} \n *Tenant:*  #{info[:tenant_name]} \n *Monthly Budget:*  #{info[:currency]} #{info[:max_amount]}\t\n *Cost To Date:*  #{info[:currency]} #{info[:cost_to_date]}"
            }
          }
        ]
    }
  end

  def self.threshold_limit_crossed(info, header='')
    { 'text': header,
      'blocks':
        [
          {
            'type': 'header',
            'text': {
              'type': 'plain_text',
              'text': header,
              'emoji': true
            }
          },
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text': "You requested that we alert you when the cost associated with your Budget exceeds the threshold limit of #{info[:threshold_value]}% for the current month.\n\nThe current cost for your cloud account linked with CloudStreet is *#{info[:currency]} #{info[:cost_to_date]}*."
            }
          },
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text': "*Name:*  #{info[:budget_name]} \n *Tenant:*  #{info[:tenant_name]} \n*Monthly Budget:*  #{info[:currency]} #{info[:max_amount]}\t\n*Cost To Date:*  #{info[:currency]} #{info[:cost_to_date]}"
            }
          }
        ]
    }
  end
end
  
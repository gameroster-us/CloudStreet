# frozen_string_literal: true

# Teams integration template
class Integrations::Teams::TeamsTemplates::Budget::Template
  def self.account_budget_limit_crossed(info, header = '')
    {
      'attachments': [
        {
          'contentType': 'application/vnd.microsoft.card.adaptive',
          "content": {
            "type": "AdaptiveCard",
            '$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
            'version': "1.2",
            'body': [
              {
                'type': 'TextBlock',
                'text': header,
                'weight': 'bolder',
                'size': 'medium'
              },
              {
                'type': 'TextBlock',
                'text': "You requested that we alert you when the cost associated with your budget exceeds #{info[:currency]} #{info[:max_amount]} for the current month.",
                'wrap': true
              },
              {
                'type': 'TextBlock',
                'text': "The current cost for your cloud account linked with CloudStreet is #{info[:currency]} #{info[:cost_to_date]}",
                'wrap': true
              },
              {
                'type': 'FactSet',
                'facts': [
                  {
                    'title': 'Name:',
                    'value': "#{info[:budget_name]}"
                  },
                  {
                    'title': 'Tenant:',
                    'value': "#{info[:tenant_name]}"
                  },
                  {
                    'title': 'Monthly Budget:',
                    'value': "#{info[:currency]} #{info[:max_amount]}"
                  },
                  {
                    'title': 'Cost To Date:',
                    'value': "#{info[:currency]} #{info[:cost_to_date]}"
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  end

  def self.threshold_limit_crossed(info, header = '')
    {
      'attachments': [
        {
          'contentType': 'application/vnd.microsoft.card.adaptive',
          'content': {
            'type': 'AdaptiveCard',
            '$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
            'version': '1.2',
            'body': [
              {
                'type': 'TextBlock',
                'text': header,
                'weight': 'bolder',
                'size': 'medium'
              },
              {
                'type': 'TextBlock',
                'text': "You requested that we alert you when the cost associated with your Budget exceeds the threshold limit of #{info[:threshold_value]}% for the current month.",
                'wrap': true
              },
              {
                'type': 'TextBlock',
                'text': "The current cost for your cloud account linked with CloudStreet is #{info[:currency]} #{info[:cost_to_date]}.",
                "wrap": true
              },
              {
                'type': 'FactSet',
                'facts': [
                  {
                    'title': 'Name:',
                    'value': "#{info[:budget_name]}"
                  },
                  {
                    'title': 'Tenant:',
                    'value': "#{info[:tenant_name]}"
                  },
                  {
                    'title': 'Monthly Budget:',
                    'value': "#{info[:currency]} #{info[:max_amount]}"
                  },
                  {
                    'title': 'Cost To Date:',
                    'value': "#{info[:currency]} #{info[:cost_to_date]}"
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  end
end

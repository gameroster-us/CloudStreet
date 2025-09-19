# frozen_string_literal: true

# Dynamic templates collection slack security notifications.
class Integrations::Slack::SlackTemplates::Security::Template
  def self.security_threat(info)
    header = build_header(info)
    data_hash = build_data_hash(info)
    footer = build_footer(info)
    payload = header.to_a + data_hash.to_a + footer.to_a
    { 'text': 'Security Adviser Security Rule change', "blocks": payload }
  end

  def self.build_data_hash(info)
    data = []
    if info[:threat_data].present?
      info[:threat_data].each do |threat|
        data << {
          'type': 'section',
          'text': {
            'type': 'mrkdwn',
            'text': "*Service ID*:  #{threat[:provider_id]} \n*Name*:  #{threat[:service_name]}\n*Service Type*:  #{threat[:service_type]}\n*Account Name (Adapter)*:  #{threat[:adapter_name]}\n*Region*:  #{threat[:region_name]} \n*(CloudStreet Rule ID) Security Rule title*:  #{(threat[:CS_rule_id])} #{threat[:scan_details]}"
          }
        }

        data << {
          'type': 'divider'
        }
      end
    end
    data
  end

  def self.build_header(info)
    notification_config = info[:notification_config]
    threat_rules = info[:threat_rules]
    data = []
    data << {
      'type': 'header',
      'text': {
        'type': 'plain_text',
        'text': 'Security Adviser Security Rule change',
        'emoji': true
      }
    }
    data << {
      'type': 'section',
      'text': {
        'type': 'mrkdwn',
        'text': "Hi,\n\nWe have detected the following changes in your cloud environment.\n\nNotification Name- #{notification_config.name}\n\nSeverity- #{notification_config.severity.map(&:titlecase).join(',')}"
      }
    }
    data << {
      'type': 'divider'
    }
    data
  end

  def self.build_footer(info)
    [{
      'type': 'section',
      'text': {
        'type': 'mrkdwn',
        'text': "For more details  <#{info[:redirect_url]}|Click Here>\n\nThanks,\nThe CloudStreet Team"
      }
    }]
  end
end

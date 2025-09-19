# frozen_string_literal: true

# Dynamic templates collection slack ri notification notifications.
class Integrations::Slack::SlackTemplates::ReservedInstance::Template
  def self.send_ri_expiry_notification(info)
    data = ri_expiry_header(info).to_a + ri_expiry_data(info).to_a + footer(info).to_a
    { 'text': "#{info['header']}", 'blocks': data }
  end

  def self.send_azure_ri_expiry_notification(info)
    data = azure_ri_expiry_header(info).to_a + azure_ri_expiry_data(info).to_a + footer(info).to_a
    { 'text': "#{info['header']}", 'blocks': data }
  end

  def self.send_under_utilized_notification(info)
    data = ri_utilized_header(info).to_a + ri_utilized_data(info).to_a + footer(info).to_a
    { 'text': "#{info['header']}", 'blocks': data }
  end

  def self.ri_expiry_header(info)
    notification_config = info['notification_config']
    header = []
    header << {
      'type': 'header',
      'text': {
        'type': 'plain_text',
        'text': "#{info['header']}",
        'emoji': true
      }
    }
    header << {
      'type': 'section',
      'text': {
        'type': 'mrkdwn',
        'text': "Hi,\n\nYour following Reserved Instances are about to expire.\n\nNotification Name- #{notification_config['name']} (Expiry before #{notification_config.dig('notify_condition', 'ri_expiry', 'days_before')} Days)"
      }
    }
    header
  end

  def self.ri_expiry_data(info)
    data = []
    ris = info['ris']
    time_zone = info['time_zone']
    if ris.present?
      ris.first(2).each do |ri|
        data << {
          'type': 'divider'
        }
        data << {
          'type': 'section',
          'text': {
            'type': 'mrkdwn',
            'text': "*Reserved Instance ID*: #{ri['reserved_instances_id']},\n *Account ID*: #{ri['account_id']}\n *Region*: #{ri['region']}\n*Instance Type*: #{ri['instance_type']}\n*Instance Count*: #{ri['instance_count']}\n*Expires on*: #{ time_zone.present? && ri['end'].present? ? ri['end'].in_time_zone(TZInfo::Timezone.get(time_zone)).strftime('%B %e, %Y at %l:%M:%S %p UTC%:z') : ri['end']}\n*Expires in Days*: #{time_zone.present? && ri['end'].present? ? (ri['end'].in_time_zone(TZInfo::Timezone.get(time_zone)) -  Date.today.in_time_zone(TZInfo::Timezone.get(time_zone))).to_i / (24*60*60): (ri['end'].to_datetime - Date.today.to_datetime).to_i}"
          }
        }
      end
    end
    data
  end

  def self.azure_ri_expiry_header(info)
    notification_config = info['notification_config']
    header = []
    header << {
      'type': 'header',
      'text': {
        'type': 'plain_text',
        'text': "#{info['header']}",
        'emoji': true
      }
    }
    header << {
      'type': 'section',
      'text': {
        'type': 'mrkdwn',
        'text': "Hi,\n\nYour following Azure Reserved Instances are about to expire.\n\nNotification Name- #{notification_config['name']} (Expiry before #{notification_config.dig('notify_condition', 'ri_expiry', 'days_before')} Days)"
      }
    }
    header
  end

  def self.azure_ri_expiry_data(info)
    data = []
    ris = info['ris']
    time_zone = info['time_zone']
    if ris.present?
      ris.first(2).each do |ri|
        data << {
          'type': 'divider'
        }
        data << {
          'type': 'section',
          'text': {
            'type': 'mrkdwn',
            'text': "*Reservation ID*: #{ri['reservation_id']}\n *Subscription ID*: #{ri['subscription_id']}\n *Location*: #{CommonConstants::AZURE_LOCATION_CODES[ri['location'].to_sym]}\n*Reserved Resource Type*: #{ri['subscription_type'].include?("Single subscription") ? ri['reserved_resource_type'] : ri['sku_name']}\n*Quantity*: #{ri['quantity']}\n*Expires on*: #{ time_zone.present? && ri['expiry_date'].present? ? ri['expiry_date'].in_time_zone(TZInfo::Timezone.get(time_zone)).strftime('%B %e, %Y at %l:%M:%S %p UTC%:z') : ri['expiry_date']}\n*Expires in Days*: #{time_zone.present? && ri['expiry_date'].present? ? (ri['expiry_date'].in_time_zone(TZInfo::Timezone.get(time_zone)) -  Date.today.in_time_zone(TZInfo::Timezone.get(time_zone))).to_i / (24*60*60): (ri['expiry_date'].to_datetime - Date.today.to_datetime).to_i}"
          }
        }
      end
    end
    data
  end

  def self.ri_utilized_header(info)
    notification_config = info['notification_config']
    header = []
    header << {
      'type': 'header',
      'text': {
        'type': 'plain_text',
        'text': "#{info['header']}",
        'emoji': true
      }
    }
    header << {
      'type': 'section',
      'text': {
        'type': "mrkdwn",
        'text': "Hi,\n\nThese are your underutilized Reserved Instances during last #{notification_config.dig('notify_condition', 'ri_under_utilization', 'last_period')} days:
\n\nNotification Name- #{notification_config['name']} (Threshold- #{notification_config.dig('notify_condition', 'ri_under_utilization', 'threshold')} Days)"
      }
    }
    header
  end

  def self.ri_utilized_data(info)
    data = []
    ris = info['ris']
    if ris.present?
      ris.first(2).each do |ri|
        data << {
          'type': 'divider'
        }
        data << {
          'type': 'section',
          "text": {
            'type': 'mrkdwn',
            'text': "*Reserved Instance ID*: #{ri['reserved_instances_id']},\n *Account ID*: #{ri['account_id']}\n *Region*: #{ri['region']}\n*Instance Type*: #{ri['instance_type']}\n*Instance Count*: #{ri['instance_count']}\n*Utilization*: #{ri['utilization']}"
          }
        }
      end
    end
    data
  end

  def self.footer(info)
    footer = []
    footer << {
      'type': 'divider'
    }
    
    footer << {
      'type': 'section',
      'text': {
        'type': 'mrkdwn',
        'text': "For more details  <#{info['url']}|Click here>\n\nThanks,\nThe CloudStreet Team"
      }
    }
    footer
  end

end

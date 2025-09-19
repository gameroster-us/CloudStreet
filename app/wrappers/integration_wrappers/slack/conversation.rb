module IntegrationWrappers::Slack::Conversation

  def conversations_list body={}
  	headers = {"Authorization" => "Bearer" + " " + access_token }
	  return self.class.http_process(IntegrationWrappers::Slack::BASE_URL, 'conversations.list','POST', {}, headers)
  end

  def conversations_info user_token, channel, body={}
  	headers = {"Authorization" => "Bearer" + " " + user_token.to_s }
    body = {"channel" => channel}
    return self.class.http_process(IntegrationWrappers::Slack::BASE_URL, 'conversations.info','POST', body, headers)
  end

  def user_conversations user_token, body={}
  	headers = {"Authorization" => "Bearer" + " " + user_token.to_s }
	  body = {"types" => "public_channel,private_channel", "exclude_archived" => true, "limit" => 999}.merge!(body)
	  return self.class.http_process(IntegrationWrappers::Slack::BASE_URL, 'users.conversations','GET', body, headers)
  end

  def conversations_members user_token, channel, body={}
    headers = {"Authorization" => "Bearer" + " " + user_token.to_s }
    body = {"channel" => channel}
    return self.class.http_process(IntegrationWrappers::Slack::BASE_URL, 'conversations.members','GET', body, headers)
  end

  def conversations_invite user_token, channel, users=[], body={}
    headers = {"Authorization" => "Bearer" + " " + user_token.to_s }
    body = {"channel" => channel, "users" => users}
    return self.class.http_process(IntegrationWrappers::Slack::BASE_URL, 'conversations.invite','POST', body, headers)
  end

end

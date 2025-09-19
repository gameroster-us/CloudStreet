module SamlSessionRepresenter
include Roar::JSON
include Roar::Hypermedia

	property :username
	#property :password
	property :authentication_token
	property :user_id
	property :account_id
	#property :errors
end
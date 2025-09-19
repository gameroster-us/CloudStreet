module Private
	module SsoConfigRepresenter
  include Roar::JSON
  include Roar::Hypermedia

	  property :idp_sso_target_url 
	  property :idp_slo_target_url
	  property :certificate
	  property :disable
	  property :account_id
	  property :idp_entity_id
	end
end
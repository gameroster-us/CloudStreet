module V2::CSIntegration::ServiceAdviser::AWS::AmisRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :completion_status
  property :total_service_count
  property :ami_type

  collection(:results,extend: ::V2::CSIntegration::ServiceAdviser::AWS::ServiceRepresenter)

  def completion_status
	self.last.first.completion_status if self.class.eql?(Array)
  end

  def total_service_count
	(self.last.first.total_service_count + self.last.second.total_service_count) if self.class.eql?(Array)
  end

  def ami_type
	self.last.first.ami_type if self.class.eql?(Array)
  end

  def results
	self.class.eql?(Array) ? (self.last.first.list + self.last.second.list) : self.list
  end
end

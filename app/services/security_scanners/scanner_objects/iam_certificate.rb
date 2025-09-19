class SecurityScanners::ScannerObjects::IamCertificate < Struct.new(:arn, :pre_heartbleed_certificate,:expired_ssl_tls, :expiration, :server_certificate_name,:expired_ssl_tls_7_days, :expired_ssl_tls_30_days,:expired_ssl_tls_45_days)
  extend SecurityScanners::ScannerObjects::ObjectParser

  def scan(rule_sets, &block)
    rule_sets.each do |rule|
      status = eval(rule["evaluation_condition"])
      yield(rule) if status
    end
  end

  class << self
      def create_new(object)
        return new(
          object.arn,
          object.upload_date.to_date < "1 apr 2014".to_date,
          !object.expiration.to_date.eql?(Date.today),
          object.expiration,
          object.server_certificate_name
      )
      end

  end

end

class SecurityScanners::ScannerObjects::IamGroup < Struct.new(:id, :name ,:users_present?, :iam_group_policy)
  extend SecurityScanners::ScannerObjects::ObjectParser

  def scan(rule_sets, &block)
    rule_sets.each do |rule|
      status = eval(rule["evaluation_condition"]) rescue false
      yield(rule) if status
    end   
  end

  class << self
      def create_new(object)
        return new(
          object.arn,
          object.group_name,
          object.users.count,
          object.list_group_policies
      )
      end
  end

end

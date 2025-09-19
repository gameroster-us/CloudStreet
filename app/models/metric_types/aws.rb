class MetricTypes::AWS < MetricTypes
  STATISTICS   = %w(Average Sum SampleCount Maximum Minimum)
  EXTENDED_STATISTICS = %w(p95.0)
  EXTENDED_STATISTICS_SERVICES = %w(Services::Compute::Server::AWS Services::Database::Rds::AWS)
  METRIC_NAMES = {
    rds: %w(CPUUtilization BinLogDiskUsage DatabaseConnections DiskQueueDepth FreeableMemory FreeStorageSpace ReplicaLag SwapUsage ReadIOPS WriteIOPS ReadLatency WriteLatency ReadThroughput WriteThroughput NetworkReceiveThroughput NetworkTransmitThroughput),
    server: %w(CPUUtilization CPUCreditUsage CPUCreditBalance DiskReadOps DiskWriteOps DiskReadBytes DiskWriteBytes NetworkIn NetworkOut StatusCheckFailed StatusCheckFailed_Instance StatusCheckFailed_System),
    volume: %w(VolumeReadBytes VolumeWriteBytes VolumeReadOps VolumeWriteOps VolumeTotalReadTime VolumeTotalWriteTime VolumeIdleTime VolumeQueueLength VolumeThroughputPercentage VolumeConsumedReadWriteOps),
    load_balancer: %w(HealthyHostCount UnHealthyHostCount RequestCount Latency HTTPCode_ELB_4XX HTTPCode_ELB_5XX HTTPCode_Backend_2XX HTTPCode_Backend_3XX HTTPCode_Backend_4XX HTTPCode_Backend_5XX BackendConnectionErrors SurgeQueueLength SpilloverCount),
    
    application_load_balancer: %w(ActiveConnectionCount ClientTLSNegotiationErrorCount ConsumedLCUs
                                  DesyncMitigationMode_NonCompliant_Request_Count DroppedInvalidHeaderRequestCount ForwardedInvalidHeaderRequestCount
                                  GrpcRequestCount HTTP_Fixed_Response_Count HTTP_Redirect_Count
                                  HTTP_Redirect_Url_Limit_Exceeded_Count HTTPCode_ELB_3XX_Count HTTPCode_ELB_4XX_Count
                                  HTTPCode_ELB_5XX_Count HTTPCode_ELB_500_Count HTTPCode_ELB_502_Count HTTPCode_ELB_503_Count
                                  HTTPCode_ELB_504_Count IPv6ProcessedBytes IPv6RequestCount NewConnectionCount NonStickyRequestCount
                                  ProcessedBytes RejectedConnectionCount RequestCount RuleEvaluations),
    
    network_load_balancer: %w(ActiveFlowCount ActiveFlowCount_TCP ActiveFlowCount_TLS ActiveFlowCount_UDP
                              ClientTLSNegotiationErrorCount ConsumedLCUs ConsumedLCUs_TCP ConsumedLCUs_TLS
                              ConsumedLCUs_UDP HealthyHostCount NewFlowCount NewFlowCount_TCP NewFlowCount_TLS
                              NewFlowCount_UDP PeakBytesPerSecond PeakPacketsPerSecond ProcessedBytes ProcessedBytes_TCP
                              ProcessedBytes_TLS ProcessedBytes_UDP ProcessedPackets TargetTLSNegotiationErrorCount TCP_Client_Reset_Count
                              TCP_ELB_Reset_Count TCP_Target_Reset_Count UnHealthyHostCount)
  }
  NAMESPACES = {
    rds: 'AWS/RDS',
    server: 'AWS/EC2',
    volume: 'AWS/EBS',
    load_balancer: 'AWS/ELB',
    network_load_balancer: 'AWS/NetworkELB',
    application_load_balancer: 'AWS/ApplicationELB'
  }
  DIMENSIONS = {
    'AWS/EC2' => 'InstanceId',
    'AWS/RDS' => 'DBInstanceIdentifier',
    'AWS/EBS' => 'VolumeId',
    'AWS/ELB' => 'LoadBalancerName',#AvailabilityZone
    'AWS/ApplicationELB' => 'LoadBalancer',
    'AWS/NetworkELB' => 'LoadBalancer'
  }

  class << self
    def lookup(params)
      {
        metric_names: metric_names_map,
        statistics: statistics_map(params),
        name_space: NAMESPACES
      }
    end

    def metric_names_map
      METRIC_NAMES.inject({}) do |mem, (type, metric_arr)|
        mem[type] = metric_arr.inject({}) { |hash_map, metric_name| hash_map[metric_name] = I18n.t("metric_types.metric_names.#{type}.#{metric_name}"); hash_map }
        mem
      end
    end

    def statistics_map(params)
      # added extra statistics depending on service type.
      stats = STATISTICS 
      stats += EXTENDED_STATISTICS if params.key?(:service_type) && EXTENDED_STATISTICS_SERVICES.include?(params[:service_type])
      stats.inject({}) { |mem, statistic| mem[statistic] = EXTENDED_STATISTICS.include?(statistic) ? statistic : statistic.underscore.titleize; mem }
    end
  end
end

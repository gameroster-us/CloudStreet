module Tasks::AWS::EventExecutionCallback
  class StartEventExecutionCallback

    def on_complete(status, options)
      if status.failures != 0
        ESLog.info "AWS Scheduled Start Event Execution Callback, batch has failures"
      else
        ESLog.info "AWS Scheduled Start Event Execution Callback completed"
      end
    end

    def on_success(status, options)
      ESLog.info "AWS Scheduled Start Event Execution Callback finished"
    end

  end

  class StopEventExecutionCallback

    def on_complete(status, options)
      if status.failures != 0
        ESLog.info "AWS Scheduled Stop Event Execution Callback, batch has failures"
      else
        ESLog.info "AWS Scheduled Stop Event Execution Callback completed"
      end
    end

    def on_success(status, options)
      ESLog.info "AWS Scheduled Stop Event Execution Callback finished"
    end

  end

  class TerminateEventExecutionCallback

    def on_complete(status, options)
      if status.failures != 0
        ESLog.info "AWS Scheduled Terminate Event Execution Callback, batch has failures"
      else
        ESLog.info "AWS Scheduled Terminate Event Execution Callback completed"
      end
    end

    def on_success(status, options)
      ESLog.info "AWS Scheduled Terminate Event Execution Callback finished"
    end

  end

  class BackupEventExecutionCallback

    def on_complete(status, options)
      if status.failures != 0
        ESLog.info "AWS Scheduled Backup Event Execution Callback, batch has failures"
      else
        ESLog.info "AWS cheduled Backup Event Execution Callback completed"
      end
    end

    def on_success(status, options)
      ESLog.info "AWS Scheduled Backup Event Execution Callback finished"
    end

  end

  class Ec2RightSizeEventExecutionCallback

    def on_complete(status, options)
      if status.failures != 0
        ESLog.info "AWS Scheduled Ec2 Right Size Event Execution Callback, batch has failures"
      else
        ESLog.info "AWS Scheduled Ec2 Right Size Event Execution Callback completed"
      end
    end

    def on_success(status, options)
      ESLog.info "AWS Scheduled Ec2 Right Size Event Execution Callback finished"
    end

  end

  class StartStopEventExecutionCallback

    def on_complete(status, options)
      if status.failures != 0
        ESLog.info "AWS Scheduled Start Stop combine Event Execution Callback, batch has failures"
      else
        # TO DO FOR START-STOP EVENT (DND)
        task = Task.find_by(id: options["task_id"])
        return unless task.present?

        task.update_columns(status: 'success')
        TaskService::Loggers::EmailLoggers.send_task_logs_email(task) if options["execute"] == "start"

        ESLog.info "AWS Scheduled Start Stop combine Event Execution Callback completed"
      end
    end

    def on_success(status, options)
      ESLog.info "AWS Scheduled Start Stop combine Event Execution Callback finished"
    end

  end

  class PolicyManualEventExecutionCallback

    def on_complete(status, options)
      if status.failures != 0
        ESLog.info "batch has failures"
      else
        task = Task.find_by(id: options["task_id"])
        return unless task.present?

        task.update_columns(status: 'success')
        TaskService::Loggers::EmailLoggers.send_task_logs_email(task) if options["execute"] == "create"

        ESLog.info "Manual Recommmendation Policy Event Execution Callback completed"
      end
    end

    def on_success(status, options)
      ESLog.info "AWS Scheduled Manual Task Recommmendation Policy Event Execution Callback finished"
    end

  end

end

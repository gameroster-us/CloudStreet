# frozen_string_literal: true

# Helper methods for scheduling Task
module TaskService::ModelHelpers::Scheduler
  # Class methods
  module ClassMethods
    def convert_duration_from_minutes_to_seconds(duration)
      return duration if duration.nil?

      duration * 60
    end
  end

  # Instance methods
  module InstanceMethods
    def generate_minutely_schedule(start_time, schedule_info)
      duration = Task.convert_duration_from_minutes_to_seconds(schedule_info[:duration])
      schedule = IceCube::Schedule.new(start_time, duration: (duration || 3600))
      interval_time = schedule_info[:interval_time] || 1
      rule = IceCube::Rule.minutely(interval_time)
      rule = add_end_rules(rule)
      schedule.add_recurrence_rule(rule)
      schedule
    end

    def generate_hourly_schedule(start_time, schedule_info)
      duration = Task.convert_duration_from_minutes_to_seconds(schedule_info[:duration])
      schedule = IceCube::Schedule.new(start_time, duration: (duration || 3600))
      interval_time = schedule_info[:interval_time] || 1
      rule = IceCube::Rule.hourly(interval_time)
      rule = add_end_rules(rule)
      schedule.add_recurrence_rule(rule)
      schedule
    end

    def generate_daily_schedule(start_time, schedule_info)
      duration = Task.convert_duration_from_minutes_to_seconds(schedule_info[:duration])
      schedule = IceCube::Schedule.new(start_time, duration: (duration || 3600))
      rule = IceCube::Rule.daily
      rule = add_end_rules(rule)
      schedule.add_recurrence_rule(rule)
      schedule
    end

    def generate_weekdays_schedule(start_time, schedule_info)
      duration = Task.convert_duration_from_minutes_to_seconds(schedule_info[:duration])
      schedule = IceCube::Schedule.new(start_time, duration: (duration || 3600))
      rule = IceCube::Rule.weekly.day(:monday, :tuesday, :wednesday, :thursday, :friday)
      rule = add_end_rules(rule)
      schedule.add_recurrence_rule(rule)
      schedule
    end

    def generate_weekly_schedule(start_time, schedule_info)
      duration = Task.convert_duration_from_minutes_to_seconds(schedule_info[:duration])
      schedule = IceCube::Schedule.new(start_time, duration: (duration || 3600))
      rule = IceCube::Rule.weekly.day(schedule_info['details']['every'].map(&:to_sym))
      rule = add_end_rules(rule)
      schedule.add_recurrence_rule(rule)
      schedule
    end

    def generate_monthly_schedule(start_time, schedule_info)
      duration = Task.convert_duration_from_minutes_to_seconds(schedule_info[:duration])
      schedule = IceCube::Schedule.new(start_time, duration: (duration || 3600))
      rule = IceCube::Rule.monthly
      rule = add_end_rules(rule)
      schedule.add_recurrence_rule(rule)
      schedule
    end

    def generate_yearly_schedule(start_time, schedule_info)
      duration = Task.convert_duration_from_minutes_to_seconds(schedule_info[:duration])
      schedule = IceCube::Schedule.new(start_time, duration: (duration || 3600))
      rule = IceCube::Rule.yearly
      rule = add_end_rules(rule)
      schedule.add_recurrence_rule(rule)
      schedule
    end

    def generate_schedule
      return if schedule.is_a?(IceCube::Schedule)

      time_zone = self.time_zone.values.uniq.join('/')
      start_time = start_datetime.in_time_zone(TZInfo::Timezone.get(time_zone))
      if !repeat?
        duration = schedule.present? && schedule[:duration].present? ? Task.convert_duration_from_minutes_to_seconds(schedule[:duration]) : 3600
        self.schedule = IceCube::Schedule.new(start_time, duration: duration)
      else
        case schedule[:occurrence]
        when 'minutely'
          self.schedule = generate_minutely_schedule(start_time, schedule)
        when 'hourly'
          self.schedule = generate_hourly_schedule(start_time, schedule)
        when 'daily'
          self.schedule = generate_daily_schedule(start_time, schedule)
        when 'weekdays'
          self.schedule = generate_weekdays_schedule(start_time, schedule)
        when 'weekly'
          self.schedule = generate_weekly_schedule(start_time, schedule)
        when 'monthly'
          self.schedule = generate_monthly_schedule(start_time, schedule)
        when 'yearly'
          self.schedule = generate_yearly_schedule(start_time, schedule)
        else
          raise "invalid occurrence type specified #{schedule_params} "
        end
      end
    end

    def add_end_rules(rule)
      if end_after_occurences_specified?
        rule.count(end_after_occurences.to_i)
      elsif end_datetime_specified?
        rule.until(end_time)
      else
        rule
      end
    end

    def end_time
      Time.parse(end_datetime)
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end

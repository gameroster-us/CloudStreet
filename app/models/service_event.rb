class ServiceEvent < ApplicationRecord
  belongs_to :service

  def cost
    # 60c an hour
    (runtime / 60 / 60) * 0.6
  end

  def runtime
    if end_date
      end_date - start_date
    else
      Time.now - start_date
    end
  end

  def duration
    days = Time.at(runtime).utc.strftime("%j").to_i - 1
    remainder = Time.at(runtime).utc.strftime("%kh %Mm %Ss")

    if days > 0
      "#{days}d #{remainder}"
    else
      remainder
    end
  end
end

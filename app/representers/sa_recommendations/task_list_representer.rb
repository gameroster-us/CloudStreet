module SaRecommendations
  module TaskListRepresenter
    include Roar::JSON
    include Roar::Hypermedia

    property :total_records, getter: lambda { |args| args[:options][:user_options][:total_records]}

    collection(
      :task_histories,
      class: SaRecommendation,
      extend: SaRecommendations::TaskHistoryRepresenter,
      embedded: true
    )

    def task_histories
      collect
    end
  end
end
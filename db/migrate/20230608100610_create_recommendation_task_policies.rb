class CreateRecommendationTaskPolicies < ActiveRecord::Migration[5.2]
  def change
    create_table :recommendation_task_policies, id: :uuid do |t|
      t.string  :name, index: true
      t.text    :description
      t.uuid    :billing_adapter_id
      t.uuid    :tenant_id
      t.uuid    :account_id
      t.string  :type, index: true
      t.string  :group_ids, array: true, default: [], index: true
      t.jsonb   :assign_to
      t.string  :frequency
      t.uuid    :user_id
      t.string  :service_category
      t.datetime :start_date
      t.timestamps
    end
  end
end

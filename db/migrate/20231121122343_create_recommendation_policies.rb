class CreateRecommendationPolicies < ActiveRecord::Migration[5.2]
  def change
    create_table :recommendation_policies, id: :uuid do |t|

      t.string :name, index: true
      t.uuid :user_id
      t.uuid :tenant_id
      t.uuid :account_id
      t.string :description
      t.string :type
      t.string :state, default: 'active'
      t.string :recommendation_type
      t.string :service_action
      t.string :services, array: true, default: []
      t.jsonb :policy_filters, default: {}
      t.string :comment
      t.string :action_mode

      t.timestamps
    end
  end
end
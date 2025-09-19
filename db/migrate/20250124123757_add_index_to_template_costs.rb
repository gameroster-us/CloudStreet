class AddIndexToTemplateCosts < ActiveRecord::Migration[5.2]
  def change
    add_index :template_costs, [:type, :region_id, :created_at], 
              order: { created_at: :desc }, 
              name: 'index_template_costs_type_region_id_created_at'
  end
end

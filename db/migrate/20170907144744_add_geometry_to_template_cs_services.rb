class AddGeometryToTemplateCSServices < ActiveRecord::Migration[5.1]
  def change
    add_column :template_CS_services, :geometry, :json
  end
end

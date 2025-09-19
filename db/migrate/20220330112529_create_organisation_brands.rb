class CreateOrganisationBrands < ActiveRecord::Migration[5.1]
  def change
    create_table :organisation_brands, id: :uuid do |t|
      t.uuid :organisation_id
      t.string :name
      t.text :product_name
      t.string :child_organisation_domain
      t.string :documentation_url
      t.string :support_url
      t.text :login_page_title
      t.text :login_page_tagline
      t.string :login_page_background_image_position
      t.string :login_page_background_image_overlay_color
      t.string :login_text_color
      t.boolean :show_privacy_policy_url
      t.string :privacy_policy_url
      t.string :privacy_policy_url_name
      t.boolean :show_terms_of_use_url
      t.string :terms_of_use_url
      t.string :terms_of_use_url_name

      t.timestamps
    end
  end
end

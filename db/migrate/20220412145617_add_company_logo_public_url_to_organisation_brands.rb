class AddCompanyLogoPublicUrlToOrganisationBrands < ActiveRecord::Migration[5.1]
  def change
    add_column :organisation_brands, :company_logo_public_url, :string
    add_column :organisation_brands, :fevicon_public_url, :string
    add_column :organisation_brands, :navigation_logo_public_url, :string
    add_column :organisation_brands, :login_page_logo_public_url, :string
    add_column :organisation_brands, :login_page_background_image_public_url, :string
  end
end

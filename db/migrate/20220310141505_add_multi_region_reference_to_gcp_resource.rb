class AddMultiRegionReferenceToGCPResource < ActiveRecord::Migration[5.1]
  def change
    add_reference :gcp_resources, :gcp_multi_regional, type: :uuid, foreign_key: true, default: nil
  end
end

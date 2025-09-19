class AddTagIdToEnvironments < ActiveRecord::Migration[5.1]
  def change
    add_column :environments, :tag_id, :uuid, unique: true

    Environment.where(tag_id: nil).each { |e| e.update_attribute(:tag_id, SecureRandom.uuid)}
  end
end

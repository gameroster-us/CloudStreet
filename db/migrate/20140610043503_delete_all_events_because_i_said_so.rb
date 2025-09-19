class DeleteAllEventsBecauseISaidSo < ActiveRecord::Migration[5.1]
  def change
    Event.delete_all
  end
end

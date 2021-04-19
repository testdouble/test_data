class AddBeepToBoops < ActiveRecord::Migration[6.1]
  def change
    change_table :boops do |t|
      t.boolean :beep, default: true
    end
  end
end

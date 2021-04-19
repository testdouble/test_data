class CreateBoops < ActiveRecord::Migration[6.1]
  def change
    create_table :boops do |t|
      t.timestamps
    end
  end
end

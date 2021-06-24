class CreatePants < ActiveRecord::Migration[6.1]
  def change
    create_table :pants do |t|
      t.string :brand
      t.timestamps
    end
  end
end

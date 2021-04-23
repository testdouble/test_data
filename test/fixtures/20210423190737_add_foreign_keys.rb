class AddForeignKeys < ActiveRecord::Migration[6.1]
  class Boop < ActiveRecord::Base
    belongs_to :other_boop, class_name: "Boop"
  end

  def change
    change_table :boops do |t|
      t.references :other_boop, foreign_key: {to_table: :boops}
    end

    reversible do |migrate|
      migrate.up do
        boops = Boop.all.to_a
        boops.each do |boop|
          boop.update!(other_boop: boops.sample)
        end
      end
      migrate.down do
      end
    end
  end
end

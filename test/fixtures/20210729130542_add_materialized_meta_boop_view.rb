class AddMaterializedMetaBoopView < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      create materialized view meta_boops as
      select
        boops.id boop_id,
        count(other_boops.id) filter (where other_boops.id < boops.id) lesser_boops_count
      from boops
      left join boops other_boops on true
      group by boops.id;
      refresh materialized view meta_boops;
    SQL
  end

  def down
    execute <<~SQL
      drop materialized view meta_boops
    SQL
  end
end

class AddTableWeWantToIgnore < ActiveRecord::Migration[6.1]
  def change
    create_table :chatty_audit_logs do |t|
      t.text :message
      t.timestamps
    end
  end
end

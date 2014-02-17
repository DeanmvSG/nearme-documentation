class DropSessions < ActiveRecord::Migration
  def up
    drop_table :sessions
  end

  def down
    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
  end
end

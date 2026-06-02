# frozen_string_literal: true

class EnsureSolidCableMessagesIdIndex < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:solid_cable_messages)

    ensure_id_column
    add_index :solid_cable_messages, :id, unique: true, if_not_exists: true
  end

  def down
    remove_index :solid_cable_messages, :id, if_exists: true
  end

  private

  def ensure_id_column
    return if column_exists?(:solid_cable_messages, :id)

    add_column :solid_cable_messages, :id, :bigint

    execute "CREATE SEQUENCE IF NOT EXISTS solid_cable_messages_id_seq OWNED BY solid_cable_messages.id"
    execute "UPDATE solid_cable_messages SET id = nextval('solid_cable_messages_id_seq') WHERE id IS NULL"
    execute "ALTER TABLE solid_cable_messages ALTER COLUMN id SET DEFAULT nextval('solid_cable_messages_id_seq')"

    change_column_null :solid_cable_messages, :id, false
  end
end

# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :username, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :users, :username, unique: true, where: "deleted_at IS NULL"
    add_index :users, :deleted_at
  end
end

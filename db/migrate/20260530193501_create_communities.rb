# frozen_string_literal: true

class CreateCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :communities, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :communities, :name, unique: true, where: "deleted_at IS NULL"
    add_index :communities, :deleted_at
  end
end

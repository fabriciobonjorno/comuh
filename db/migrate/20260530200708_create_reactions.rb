# frozen_string_literal: true

class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :message, null: false, foreign_key: true, type: :uuid
      t.string :reaction_type, null: false

      t.timestamps
    end

    add_index :reactions, %i[message_id user_id reaction_type], unique: true
  end
end

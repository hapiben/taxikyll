class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.string :token

      t.timestamps null: false
    end
  end
end

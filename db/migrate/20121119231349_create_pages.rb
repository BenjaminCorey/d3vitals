class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :permalink
      t.string :title
      t.text :content

      t.timestamps
    end
    add_index :pages, :permalink
  end
end

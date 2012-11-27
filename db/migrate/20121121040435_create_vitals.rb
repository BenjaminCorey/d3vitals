class CreateVitals < ActiveRecord::Migration
  def change
    create_table :vitals do |t|
      t.integer :patient_id
      t.string :type
      t.integer :value
      t.string :unit
      t.string :taken_at

      t.timestamps
    end
  end
end

class RenameVitalTypeColumnForVitals < ActiveRecord::Migration
  def up
    rename_column :vitals, :vital_type, :key
  end

  def down
    rename_column :vitals, :key, :vital_type
  end
end

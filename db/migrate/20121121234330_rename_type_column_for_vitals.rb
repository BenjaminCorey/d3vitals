class RenameTypeColumnForVitals < ActiveRecord::Migration
  def up
    rename_column :vitals, :type, :vital_type
  end

  def down
    rename_column :vitals, :vital_type, :type
  end
end

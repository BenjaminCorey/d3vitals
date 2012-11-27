require 'csv'

desc "Imports a CSV into an ActiveRecord table"
task :csv_model_import => :environment do |task, args|
  file = File.expand_path("../../../public/data.csv", __FILE__)
  CSV.foreach(file, headers: true) do |row|
    Vital.create!(row.to_hash)
  end
end
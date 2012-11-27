class Vital < ActiveRecord::Base
  attr_accessible :patient_id, :taken_at, :type, :unit, :value
end

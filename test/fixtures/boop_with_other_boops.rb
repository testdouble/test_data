class Boop < ApplicationRecord
  belongs_to :other_boop, class_name: "Boop"
end

class PopulationLocus < ActiveRecord::Base

  belongs_to :plant_population
  belongs_to :marker_assay

  has_many :map_positions
  has_many :map_locus_hits

  include Annotable
end

class PlantAccession < ActiveRecord::Base
  belongs_to :plant_line
  belongs_to :user

  after_update { plant_scoring_units.each(&:touch) }
  before_destroy { plant_scoring_units.each(&:touch) }

  has_many :plant_scoring_units

  validates :plant_accession,
            presence: true,
            uniqueness: true

  validates :year_produced,
            length: { is: 4 },
            allow_blank: true

  include Relatable
  include Filterable
  include Pluckable
  include Publishable
  include TableData

  def self.table_columns
    [
      'plant_accession',
      'plant_lines.plant_line_name',
      'plant_accession_derivation',
      'originating_organisation',
      'year_produced',
      'date_harvested'
    ]
  end

  def self.count_columns
    [
      'plant_scoring_units_count'
    ]
  end

  def self.permitted_params
    [
      query: params_for_filter(table_columns) +
        [
          'id'
        ]
    ]
  end

  def self.ref_columns
    [
      'plant_line_id'
    ]
  end

  include Annotable
end

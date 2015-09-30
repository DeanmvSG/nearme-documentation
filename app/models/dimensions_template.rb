class DimensionsTemplate < ActiveRecord::Base

  auto_set_platform_context
  scoped_to_platform_context
  acts_as_paranoid

  UNITS_OF_MEASURE = {
    'imperial' => {
      'length' => ['in', 'ft'],
      'weight' => ['oz', 'pound'],
    },
    'metric' => {
      'length' => ['cm', 'm'],
      'weight' => ['g', 'kg'],
    }
  }

  belongs_to :instance

  belongs_to :creator, :foreign_key => :creator_id, class_name: User

  belongs_to :entity, polymorphic: true

  validates_presence_of  :name, :weight, :height, :width, :depth

  validates_with UnitsOfMeasureValidator, :attributes => [:unit_of_measure, :weight_unit, :height_unit, :width_unit, :depth_unit]

  validates_numericality_of :weight, :height, :width, :depth, greater_than: 0

  def get_shippo_id
    self.shippo_id.presence || create_shippo_parcel[:object_id]
  end

  def create_shippo_parcel
    api = ShippoApi::ShippoApi.new(instance.shippo_api_token)
    parcel = api.create_parcel(self.to_shippo)
    update_attribute :shippo_id, parcel[:object_id]
    parcel
  end

  def to_shippo
    {
      length: converted_depth,
      width: converted_width,
      height: converted_height,
      distance_unit: common_distance_unit,
      weight: weight,
      mass_unit: weight_unit
    }
  end

  ['depth', 'height', 'width'].each do |dimension|
    define_method "converted_#{dimension}" do
      if common_unit?
        self[dimension]
      else
        convert(self[dimension], self["#{dimension}_unit"])
      end
    end
  end

  def convert(dimension, from_unit)
    case from_unit
    when 'm'
      dimension * 100
    when 'ft'
      dimension * 12
    else
      dimension
    end
  end

  def common_unit?
    [width_unit, height_unit, depth_unit].uniq.size == 1
  end

  def common_distance_unit
    if common_unit?
      width_unit
    else
      imperial? ? 'in' : 'cm'
    end
  end

  def imperial?
    unit_of_measure == "imperial"
  end

end

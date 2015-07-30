class Address < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid
  scoped_to_platform_context

  # attr_accessible :address, :address2, :latitude, :local_geocoding, :longitude, :suburb,
  #   :formatted_address, :postcode, :city, :state, :country, :street, :address_components

  attr_accessor :local_geocoding # set this to true in js

  serialize :address_components, JSON
  geocoded_by :address

  belongs_to :instance
  belongs_to :entity, -> { with_deleted }, polymorphic: true

  validates_presence_of :address, :latitude, :longitude
  before_validation :update_address
  before_validation :parse_address_components
  before_save :retry_fetch, if: lambda { |a| a.country.nil? }

  scope :bounding_box, -> (box) {
    where('addresses.latitude > ? AND addresses.latitude < ?', box.last.first, box.first.first).
    where('addresses.longitude > ? AND addresses.longitude < ?', box.last.last, box.first.last)
  }

  after_save do
    if entity.is_a?(Location)
      entity.listings.each do |l|
        ElasticIndexerJob.perform(:update, l.class.to_s, l.id)
      end
    end
  end

  def self.order_by_distance_sql(latitude, longitude)
    distance_sql(latitude, longitude, order: "distance")
  end

  def distance_from(other_latitude, other_longitude)
    Geocoder::Calculations.distance_between([ latitude, longitude ], [ other_latitude, other_longitude ], units: :km)
  end

  def street
    super.presence || address.try { |a| a.split(",")[0] }
  end

  def suburb
    super.presence
  end

  def city
    super.presence
  end

  def state
    super.presence
  end

  def country
    super.presence
  end

  def postcode
    super.presence
  end

  def address
    read_attribute(:formatted_address).presence || read_attribute(:address)
  end

  def state_code
    @state_code ||= Address::GoogleGeolocationDataParser.new(address_components).fetch_address_component("state", :short)
  end

  def parse_address_components
    if address_components_changed?
      parse_address_components!
    end
  end

  def parse_address_components!
    data_parser = Address::GoogleGeolocationDataParser.new(address_components)
    self.city = data_parser.fetch_address_component("city")
    self.suburb = data_parser.fetch_address_component("suburb")
    self.street = data_parser.fetch_address_component("street")
    self.country = data_parser.fetch_address_component("country")
    self.iso_country_code = data_parser.fetch_address_component("country", :short)
    self.state = data_parser.fetch_address_component("state")
    self.postcode = data_parser.fetch_address_component("postcode")
  end

  def retry_fetch
    fetch_coordinates!
    parse_address_components!
  end

  def to_s
    self.address
  end

  def self.xml_attributes
    [:address, :address2, :formatted_address, :city, :street, :state, :postcode]
  end

  def self.csv_fields
    { address: 'Address', city: 'City', street: 'Street', suburb: 'Suburb', state: 'State', postcode: 'Postcode' }
  end

  def update_address
    if should_fetch_coordinates?
      fetch_coordinates!
    elsif should_fetch_address?
      fetch_address!
    end
    nil
  end

  def fetch_coordinates!
    populator = Address::AddressComponentsPopulator.new(self)
    geocoded = populator.geocode
    if geocoded
      self.latitude = geocoded.coordinates[0]
      self.longitude = geocoded.coordinates[1]
      self.formatted_address = geocoded.formatted_address
      self.address_components = populator.wrapped_address_components
    else
      # do not allow to save when cannot geolocate
      self.latitude = nil
      self.longitude = nil
    end
    geocoded
  end

  def fetch_address!
    populator = Address::AddressComponentsPopulator.new(self)
    geocoded = populator.reverse_geocode
    if geocoded
      self.address = geocoded.formatted_address
      self.formatted_address = geocoded.formatted_address
      self.address_components = populator.wrapped_address_components
    else
      # do not allow to save when cannot geolocate
      self.address = nil
    end
    geocoded
  end

  def should_fetch_coordinates?
    address_changed? && (!(latitude_changed? || longitude_changed?) || (latitude.blank? && longitude.blank?))
  end

  def should_fetch_address?
    (!address_changed? && (latitude_changed? || longitude_changed?))
  end

  def to_liquid
    AddressDrop.new(self)
  end

end

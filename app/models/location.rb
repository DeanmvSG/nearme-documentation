class Location < ActiveRecord::Base
  class NotFound < ActiveRecord::RecordNotFound; end
  has_paper_trail
  extend FriendlyId
  friendly_id :formatted_address, use: :slugged

  include Impressionable

  attr_accessible :address, :address2, :amenity_ids, :company_id, :description, :email,
    :info, :latitude, :local_geocoding, :longitude, :currency,
    :formatted_address, :availability_rules_attributes, :postcode, :phone,
    :availability_template_id, :special_notes, :listings_attributes, :suburb,
    :city, :state, :country, :street, :address_components, :location_type_id, :photos,
    :administrator_id, :name
  attr_accessor :local_geocoding # set this to true in js
  attr_accessor :name_required

  liquid_methods :name

  serialize :address_components, JSON

  geocoded_by :address

  has_many :amenity_holders, as: :holder
  has_many :amenities, through: :amenity_holders

  belongs_to :company, inverse_of: :locations
  belongs_to :location_type
  belongs_to :administrator, class_name: "User", :inverse_of => :administered_locations

  delegate :creator, :to => :company, :allow_nil => true
  delegate :company_users, :to => :company, :allow_nil => true

  after_save :notify_user_about_change
  after_destroy :notify_user_about_change

  delegate :notify_user_about_change, :to => :company, :allow_nil => true
  delegate :phone, :to => :creator, :allow_nil => true

  has_many :listings,
    dependent:  :destroy,
    inverse_of: :location

  has_one :instance, through: :company

  has_many :photos, :through => :listings

  has_many :availability_rules, :order => 'day ASC', :as => :target

  has_many :impressions, :as => :impressionable, :dependent => :destroy

  validates_presence_of :company, :address, :latitude, :longitude, :location_type_id, :currency
  validates_presence_of :description 
  validates_presence_of :name, :if => :name_required
  validates :email, email: true, allow_nil: true
  validates :currency, currency: true, allow_nil: false
  validates_length_of :description, :maximum => 250

  before_validation :fetch_coordinates
  before_validation :parse_address_components
  before_save :assign_default_availability_rules

  scope :filtered_by_location_types_ids,  lambda { |location_types_ids| where('locations.location_type_id IN (?)', location_types_ids) }
  scope :filtered_by_industries_ids,  lambda { |industry_ids| joins(:company => :company_industries).where('company_industries.industry_id IN (?)', industry_ids) }
  scope :none, where(:id => nil)
  scope :for_instance, ->(instance) { joins(:instance).includes(:instance).where(:'instances.id' => instance.id) }
  scope :with_searchable_listings, where(%{ (select count(*) from "listings" where location_id = locations.id and listings.draft IS NULL and enabled = 't' and listings.deleted_at is null) > 0 })

  acts_as_paranoid

  # Useful for storing the full geo info for an address, like time zone
  serialize :info, Hash

  # Include a set of helpers for handling availability rules and interface onto them
  include AvailabilityRule::TargetHelper
  accepts_nested_attributes_for :availability_rules, :allow_destroy => true
  accepts_nested_attributes_for :listings

  delegate :url, :to => :company
  delegate :service_fee_guest_percent, to: :company, allow_nil: true
  delegate :service_fee_host_percent, to: :company, allow_nil: true

  def distance_from(other_latitude, other_longitude)
    Geocoder::Calculations.distance_between([ latitude,       longitude ],
                                            [ other_latitude, other_longitude ],
                                            units: :km)
  end

  def name
    read_attribute(:name).presence || [company.name, street].compact.join(" @ ")
  end

  def admin?(user)
    creator == user
  end

  def currency
    super.presence || "USD"
  end

  def street
    super.presence || address.try{|a| a.split(",")[0] }
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

  def parse_address_components
    if address_components_changed?
      data_parser = Location::GoogleGeolocationDataParser.new(address_components)
      self.city = data_parser.fetch_address_component("city")
      self.suburb = data_parser.fetch_address_component("suburb")
      self.street = data_parser.fetch_address_component("street")
      self.country = data_parser.fetch_address_component("country")
      self.state = data_parser.fetch_address_component("state")
      self.postcode = data_parser.fetch_address_component("postcode")
    end
  end

  def description
    read_attribute(:description).presence || (listings.first || NullListing.new).description
  end

  def administrator
    super.presence || creator
  end

  def creator=(creator)
    company.creator = creator
    company.save
  end

  def email
    read_attribute(:email).presence || creator.try(:email) 
  end

  def phone=(phone)
    creator.phone = phone if creator.phone.blank? if creator
  end

  def to_liquid
    LocationDrop.new(self)
  end

  def timezone
    NearestTimeZone.to(latitude, longitude)
  end

  def local_time
    Time.now.in_time_zone(timezone)
  end

  def self.xml_attributes
    [:address, :address2, :formatted_address, :city, :street, :state, :postcode, :email, :phone, :description, :special_notes, :currency]
  end

  private

  def assign_default_availability_rules
    if availability_rules.reject(&:marked_for_destruction?).empty?
      AvailabilityRule.default_template.apply(self)
    end
  end

  def fetch_coordinates
    # If we aren't locally geocoding (cukes and people with JS off)
    if (address_changed? && !(latitude_changed? || longitude_changed?))
      geocoded = Geocoder.search(read_attribute(:address)).try(:first)
      if geocoded
        self.latitude = geocoded.coordinates[0]
        self.longitude = geocoded.coordinates[1]
        self.formatted_address = geocoded.formatted_address
        populator = Location::AddressComponentsPopulator.new
        populator.set_result(geocoded)
        self.address_components = populator.wrap_result_address_components
      else
        # do not allow to save when cannot geolocate
        self.latitude = nil
        self.longitude = nil
      end
    end
  end
end

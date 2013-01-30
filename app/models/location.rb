class Location < ActiveRecord::Base
  attr_accessible :address, :amenity_ids, :company_id, :description, :email,
    :info, :latitude, :local_geocoding, :longitude, :name,
    :currency, :phone, :formatted_address, :availability_rules_attributes,
    :availability_template_id,
    :special_notes, :listings_attributes, :suburb, :city, :state, :country, :address_components
  attr_accessor :local_geocoding # set this to true in js

  serialize :address_components, JSON

  geocoded_by :address

  has_many :amenities, through: :location_amenities
  has_many :location_amenities

  belongs_to :company
  delegate :creator, :to => :company

  has_many :listings,
           :dependent => :destroy

  has_many :photos, :through => :listings
  has_many :feeds, :through => :listings

  has_many :availability_rules, :as => :target

  validates_presence_of :company_id, :name, :description, :address, :latitude, :longitude
  validates :email, email: true, allow_nil: true
  validates :currency, currency: true, allow_nil: true
  validates_length_of :description, :maximum => 250

  before_validation :fetch_coordinates
  before_save :assign_default_availability_rules
  before_save :parse_address_components

  acts_as_paranoid

  # Useful for storing the full geo info for an address, like time zone
  serialize :info, Hash

  # Include a set of helpers for handling availability rules and interface onto them
  include AvailabilityRule::TargetHelper
  accepts_nested_attributes_for :availability_rules, :allow_destroy => true
  accepts_nested_attributes_for :listings

  delegate :url, :to => :company

  def distance_from(other_latitude, other_longitude)
    Geocoder::Calculations.distance_between([ latitude,       longitude ],
                                            [ other_latitude, other_longitude ],
                                            units: :km)
  end

  def admin?(user)
    creator == user
  end

  SUPPORTED_FIELDS = {
    "route" => "street",
    "country" => "country",
    "locality"  =>  "city",
    "sublocality" => "suburb",
    "administrative_area_level_1" => "state",
  }

  def parse_address_components
      if address_components_changed?
        data_parser = Location::GoogleGeolocationDataParser.new(address_components)
        SUPPORTED_FIELDS.values.each do |component|
            begin
              self.send("#{component}=".to_sym, data_parser.send(component.to_sym))
            rescue
              # nothing happened - one of the expected supported fields was not found
            end
        end
      end
  end

  def description
    read_attribute(:description) || (listings.first || NullListing.new).description
  end

  def creator=(creator)
    company.creator = creator
    company.save
  end

  private

    def assign_default_availability_rules
      if !availability_rules.any?
        AvailabilityRule.default_template.apply(self)
      end
    end

    def fetch_coordinates
      # If we aren't locally geocoding (cukes and people with JS off)
      if address_changed? && !(latitude_changed? || longitude_changed?)
        geocoded = Geocoder.search(address).try(:first)
        if geocoded
          self.latitude = geocoded.coordinates[0]
          self.longitude = geocoded.coordinates[1]
          self.formatted_address = geocoded.formatted_address
        end
      end
    end

end

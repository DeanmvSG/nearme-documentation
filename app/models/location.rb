class Location < ActiveRecord::Base
  attr_accessible :address, :company_id, :creator_id, :description, :email,
    :info, :latitude, :local_geocoding,  :longitude, :name, :phone, :formatted_address
  attr_accessor :local_geocoding # set this to true in js
  geocoded_by :address

  has_many :amenities, through: :location_amenities
  has_many :location_amenities

  has_many :organizations, through: :location_organizations
  has_many :location_organizations

  belongs_to :company
  belongs_to :creator, class_name: "User"
  has_many :listings

  validates_presence_of :company_id, :name, :description, :address, :latitude, :longitude
  validates :email, email: true, allow_nil: true

  before_validation :fetch_coordinates

  acts_as_paranoid

  # Useful for storing the full geo info for an address, like time zone
  serialize :info, Hash

  private

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
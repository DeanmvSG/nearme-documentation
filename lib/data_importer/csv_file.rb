require 'csv'

class DataImporter::CsvFile < DataImporter::File
  attr_accessor :hour_parser

  def initialize(path)
    super(path)
    @csv_handle = CSV.new(open(@path))
  end

  def next_row
    @current_row = @csv_handle.shift
  end

  def row_as_hash
    {
      user: user_attributes,
      company: company_attributes,
      location: location_attributes,
      address: address_attributes,
      listing: listing_attributes,
      photo: photo_attributes
    }
  end

  def user_attributes
    fail NotImplementedError
  end

  def company_attributes
    fail NotImplementedError
  end

  def location_attributes
    fail NotImplementedError
  end

  def address_attributes
    fail NotImplementedError
  end

  def listing_attributes
    fail NotImplementedError
  end

  def photo_attributes
    fail NotImplementedError
  end

  def amenities
    []
  end

  def send_invitation
    @options.fetch(:send_invitational_email)
  end

  def sync_mode
    @options.fetch(:sync_mode)
  end
end

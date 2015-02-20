class DataUpload < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid
  auto_set_platform_context
  scoped_to_platform_context

  belongs_to :instance
  belongs_to :importable, polymorphic: true
  belongs_to :uploader, class_name: 'User'
  belongs_to :target, polymorphic: true
  serialize :parse_summary, Hash

  mount_uploader :csv_file, DataImportFileUploader
  mount_uploader :xml_file, DataImportFileUploader
  validates :csv_file, :presence => true, :file_size => { :maximum => 10.megabytes.to_i }

  store :options, accessors: [ :send_invitational_email, :sync_mode ], coder: Hash
  scope :for_importable, -> (importable) { where(importable: importable) }

  state_machine :state, initial: :queued do

    event :process do
      transition queued: :processing
    end

    event :queue do
      transition processing: :queued
    end

    event :import do
      transition queued: :importing
    end

    event :finish do
      transition importing: :succeeded
    end

    event :finish_with_validation_errors do
      transition importing: :partially_succeeded
    end

    event :fail do
      transition [:processing, :importing] => :failed
    end
  end

  def sync_mode
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean(super)
  end

  def send_invitational_email
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean(super)
  end

  def num_rows
    if csv_file.file && File.exists?(csv_file.file.path)
      # don't want to open the file to count the rows, so the command
      # don't count headers so -1
      @num_rows ||= `wc -l #{csv_file.proper_file_path}`.to_i - 1
    else
      raise IOError, 'No CSV file'
    end
  end

  def should_be_monitored?
    queued? || processing? || importing?
  end

  def to_liquid
    DataUploadDrop.new(self)
  end

end


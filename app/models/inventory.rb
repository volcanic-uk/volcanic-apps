class Inventory < ActiveRecord::Base

  validates :name, presence: true
  validates :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :object_action, presence: true

  scope :by_dataset, -> id { where(dataset_id: id) }
  scope :by_object, -> type { where(object_action: type) }

  # Calls strftime on start_date and returns a human-friendly version
  def human_start_date
    self.start_date.strftime(strftime_string)
  end

  def human_end_date
    self.end_date.strftime(strftime_string)
  end

  def within_date
    active_start = start_date.nil? || start_date <= Date.today
    active_end = end_date.nil? || end_date >= Date.today
    active_start && active_end
  end

  def self.object_actions
    # ['Activate Job Listing for 7 days', 'Activate Job Listing for 30 days', 'Activate Featured Job Listing for 7 days', 'Activate Featured Job Listing for 30 days', 'Schedule as Job of the Week', 'Mark Job Listing as paid', 'Purchase credits', 'Provide Candidate search for x days', 'Provide CV Downloads for x days', 'Deduct a credit']
    ['Activate Job Listing for 7 days', 'Activate Job Listing for 30 days', 'Activate Featured Job Listing for 7 days', 'Activate Featured Job Listing for 30 days', 'Schedule as Job of the Week', 'Deduct a credit', 'Mark Liked Job as Paid']   
  end

  def self.object_types(dataset_id = nil)
    object_types = [
      { type: 'Credit' },
      { type: 'Job' },
      { type: 'Referral' }
    ]

    case dataset_id
    when 18
      object_types.delete({type: 'Job' }) # replaced with bespoke types
      object_types.concat ([
        { type: 'EG_Job_individual_employer' },
        { type: 'EG_Job_employer'}]
      )
    when 55
      object_types.concat ([
        { type: 'Premium Job' },
        { type: 'Job of the Week' }]
      )
    end
    object_types
  end

private
  def strftime_string
    "%d %B %Y"
  end


end

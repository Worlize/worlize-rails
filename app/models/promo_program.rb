class PromoProgram < ActiveRecord::Base
  has_many :marketplace_item_giveaways
  has_many :marketplace_item_giveaway_receipts, :through => :marketplace_item_giveaways
  
  has_many :image_assets, :as => :imageable, :dependent => :destroy

  validate :validate_date_range
  
  validates :name, :presence => true
  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :mode, :presence => true
  validates :mode, :inclusion => {
              :in => %w(adhoc daily_giveaway),
              :message => "must be either Ad-Hoc or Daily Giveaway",
              :if => Proc.new { |i| !i.mode.empty? }
            }

  scope :current, lambda {
    # Time.current or Time.zone.now uses the local timezone, Time.now does not
    where(['start_date <= DATE(?) AND end_date >= DATE(?)', Time.current.to_date, Time.current.to_date])
  }
  
  scope :daily_giveaways, lambda {
    where(:mode => 'daily_giveaway')
  }
  
  scope :gift_not_received_today_by_user, lambda { |user|
    where([
     "(SELECT count(1)
          FROM marketplace_item_giveaways AS g
          INNER JOIN marketplace_item_giveaway_receipts AS r
              ON r.marketplace_item_giveaway_id = g.id
          WHERE g.promo_program_id = promo_programs.id
              AND g.date = ?
              AND r.user_id = ?
      ) = 0", Time.current.to_date, user.id])
  }
  
  scope :has_gift_available_today, lambda {
    where([
      "(SELECT count(1)
            FROM marketplace_item_giveaways AS g
            WHERE g.promo_program_id = promo_programs.id
                AND g.date = ?
       ) > 0",
       Time.current.to_date])
  }
  
  def self.mode_options
    [
      ['Ad-Hoc', 'adhoc'],
      ['Daily Giveaway','daily_giveaway']
    ]
  end

  def items_given_away_count
    count = 0
    self.marketplace_item_giveaways.all.each do |giveaway|
      count += giveaway.marketplace_item_giveaway_receipts.count
    end
    count
  end
  
  private
  
  def validate_date_range
    if !start_date.nil? && !end_date.nil?
      self.errors.add(:start_date, 'cannot be after the end date') if start_date > end_date
    end
  end

end

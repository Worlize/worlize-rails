class DialogsController < ApplicationController
  before_filter :require_user

  def check_for_dialogs
    # First, Check for daily-giveaway programs where the user hasn't yet
    # received their gift for today.
    programs_with_todays_gift_not_yet_received =
      PromoProgram.
        current.
        daily_giveaways.
        has_gift_available_today.
        gift_not_received_today_by_user(current_user)

    # Then bestow the gift(s) upon the user
    daily_giveaway_programs = programs_with_todays_gift_not_yet_received.map do |promo|
      promo.marketplace_item_giveaways.for_today.each do |giveaway|
        item = giveaway.marketplace_item.item
        gift = item.gifts.create(
          :sender => nil,
          :recipient => current_user,
          :note => nil
        )
        
        require 'pp'
        pp gift.errors
        
        # Create a receipt for the gift.  This will allow us to know if the
        # gift has already been received if the user comes back again later.
        receipt = giveaway.marketplace_item_giveaway_receipts.build(:user => current_user)
        receipt.save
      end
    end
    
    # TODO: Optimize the lookup of how many gifts were received on
    # each day.  Potential query:
    #
    # SELECT giveaways.promo_program_id, giveaways.date,
    #     (SELECT count(1)
    #      FROM marketplace_item_giveaway_receipts AS receipts
    #      WHERE receipts.marketplace_item_giveaway_id = giveaways.id
    #         AND receipts.user_id = ?) AS count
    # FROM marketplace_item_giveaways AS giveaways
    # WHERE giveaways.promo_program_id = ?
    # GROUP BY giveaways.date
    # ORDER BY giveaways.date ASC;
    

    promo_stats = programs_with_todays_gift_not_yet_received.map do |promo|
      day_index = 0
      status_by_date = (promo.start_date..promo.end_date).map do |date| 
        day_index = day_index + 1
        
        if date > Time.current.to_date
          # No point checking if they've received a gift that's scheduled
          # to be given in the future
          receipt_count = 0
        else
          receipt_count = 
            current_user.
              marketplace_item_giveaway_receipts.
              for_promo_program(promo).
              for_date(date).
              count
        end
        {
          :day_index => day_index,
          :date => date.to_s,
          :gift_received => receipt_count > 0
        }
      end
      
      {
        :promo => {
          :id => promo.id,
          :name => promo.name,
          :dialog_css => promo.dialog_css,
          :start_date => promo.start_date,
          :end_date => promo.end_date
        },
        :status_by_date => status_by_date
      }
    end
    
    render :json => promo_stats
  end

end

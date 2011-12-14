class DialogsController < ApplicationController
  before_filter :require_user, :except => [:css]

  def css
    render :text => PromoProgram.current.map {|p| p.dialog_css }.join("\n"), :content_type => 'text/css'
  end

  def check_for_dialogs
    active_programs = PromoProgram.current
    
    programs_with_gift_given_today = {}
    
    active_programs.each do |promo|
      # See if there are any items to give the user today that they haven't
      # received quite yet.
      promo.marketplace_item_giveaways.for_today.not_received_by_user(current_user).each do |giveaway|
        # Bestow the gift(s) upon the user
        programs_with_gift_given_today[promo.id] = true
        
        item = giveaway.marketplace_item.item
        gift = item.gifts.create(
          :sender => nil,
          :recipient => current_user,
          :note => nil
        )
        
        # Create a receipt for the gift.  This will allow us to know if the
        # gift has already been received if the user comes back again later.
        receipt = giveaway.marketplace_item_giveaway_receipts.build(:user => current_user)
        receipt.save
      end
    end
    
    promo_stats = []
    
    active_programs.daily_giveaways.each do |promo|
      next unless programs_with_gift_given_today[promo.id]
      
      day_index = 0
      status_by_date = (promo.start_date..promo.end_date).map do |date| 
        day_index = day_index + 1
        
        if date > Time.current.to_date
          # No point checking if they've received a gift that's scheduled
          # to be given in the future
          status = 'not-received-yet'
        else
          receipt_count = 
            current_user.
              marketplace_item_giveaway_receipts.
              for_promo_program(promo).
              for_date(date).
              count
          status = (receipt_count == 0) ? 'missed' : 'received'
        end
        
        {
          :day_index => day_index,
          :date => date.to_s,
          :status => status
        }
      end
      
      promo_stats.push({
        :promo => {
          :id => promo.id,
          :mode => promo.mode,
          :name => promo.name,
          :start_date => promo.start_date,
          :end_date => promo.end_date
        },
        :status_by_date => status_by_date
      })
    end
    
    render :json => {
      :success => true,
      :dialogs => promo_stats
    }
    
    # # First, Check for daily-giveaway programs where the user hasn't yet
    # # received their gift for today.
    # programs_with_todays_gift_not_yet_received =
    #   PromoProgram.
    #     current.
    #     daily_giveaways.
    #     has_gift_available_today.
    #     gift_not_received_today_by_user(current_user)
    # 
    # # Then bestow the gift(s) upon the user
    # programs_with_todays_gift_not_yet_received.each do |promo|
    #   promo.marketplace_item_giveaways.for_today.each do |giveaway|
    #     item = giveaway.marketplace_item.item
    #     gift = item.gifts.create(
    #       :sender => nil,
    #       :recipient => current_user,
    #       :note => nil
    #     )
    #     
    #     # Create a receipt for the gift.  This will allow us to know if the
    #     # gift has already been received if the user comes back again later.
    #     receipt = giveaway.marketplace_item_giveaway_receipts.build(:user => current_user)
    #     receipt.save
    #   end
    # end
    
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
    

  end

end

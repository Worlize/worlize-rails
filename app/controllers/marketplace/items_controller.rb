class Marketplace::ItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  before_filter :require_user
  layout 'marketplace'

  def show
    
  end
  
  def buy
    errors = []
    item = MarketplaceItem.active.find_by_id(params[:id])
    begin
      case item.item_type
        when 'Avatar'
          if current_user.avatar_slots <= current_user.avatar_instances.count
            raise "You do not have enough open slots in your avatar locker.  Add more locker space and try again."
          end
        when 'InWorldObject'
          if current_user.in_world_object_slots <= current_user.in_world_object_instances.count
            raise "You do not have enough open slots in your object locker.  Add more locker space and try again."
          end
        when 'Prop'
          if current_user.prop_slots <= current_user.prop_instances.count
            raise "You do not have enough open slots in your props locker.  Add more locker space and try again."
          end
        when 'Background'
          if current_user.background_slots <= current_user.background_instances.count
            raise "You do not have enough open slots in your backgrounds locker.  Add more locker space and try again."
          end
        else
      end
      
      # Create the purchase record...
      MarketplacePurchaseRecord.create!(
        :user => current_user,
        :marketplace_item => item,
        :currency_id => item.currency_id,
        :purchase_price => item.price
      )

      # Put the product into the user's locker...
      instance = item.item.instances.create!(:user => current_user)
      
      # Finally, charge the customer if all has gone well.
      if item.price > 0
        if item.currency_id == 1
          current_user.debit_bucks(item.price)
        elsif item.currency_id == 2
          current_user.debit_coins(item.price)
        end
      end

      coins = current_user.coins
      bucks = current_user.bucks
      
      render :json => Yajl::Encoder.encode({
        :success => true,
        :formatted_coins => number_with_delimiter(coins),
        :formatted_bucks => number_with_delimiter(bucks),
        :coins => coins,
        :bucks => bucks
      })
    rescue Exception => e
      errors.push(e.to_s)
      coins = current_user.coins
      bucks = current_user.bucks
      render :json => Yajl::Encoder.encode({
        :success => false,
        :formatted_coins => number_with_delimiter(coins),
        :formatted_bucks => number_with_delimiter(bucks),
        :coins => coins,
        :bucks => bucks,
        :errors => errors
      }), :status => 500
    end
  end

end

class Locker::SlotsController < ApplicationController
  before_filter :require_user
  
  def show
    result = {
      :success => true
    }
    %w(avatar background in_world_object prop).each do |slot_kind|
      result[slot_kind+'_slots'] = current_user.send(slot_kind+'_slots')
    end
    render :json => result
  end
  
  def prices
    result = {
      :success => true
    }
    %w(avatar background in_world_object prop).each do |slot_kind|
      price = LockerSlotPrice.find_by_slot_kind(slot_kind)
      result[slot_kind+'_slot_price'] = price.nil? ? 0 : price.bucks_amount.to_i
    end
    render :json => result
  end
  
  def buy
    slot_kind = params[:slot_kind]
    quantity = params[:quantity].to_i
    
    begin
      current_user.buy_slots(slot_kind, quantity)
    rescue Worlize::InsufficientFundsException => e
      render :json => {
        :success => false,
        :insufficient_funds => true,
        :message => e.message
      } and return
    rescue => e
      render :json => {
        :success => false,
        :insufficient_funds => false,
        :message => e.message
      } and return
    end
    
    render :json => {
      :success => true,
      :slot_kind => slot_kind,
      :quantity_purchased => quantity,
      :new_slot_counts => {
        :avatar_slots => current_user.avatar_slots,
        :background_slots => current_user.background_slots,
        :in_world_object_slots => current_user.in_world_object_slots,
        :prop_slots => current_user.prop_slots
      }
    }
  end
end

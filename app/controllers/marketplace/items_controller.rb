class Marketplace::ItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  layout 'marketplace'
    
  before_filter :require_user, :only => [ :buy ]
  before_filter :store_location_if_not_logged_in, :except => [ :show ]

  def index
    @category = MarketplaceCategory.find_by_id(params[:category_id])
    @items = @category.marketplace_items
    case params[:item_type]
      when 'Avatar'
        @display_item_type = 'Avatars'
        @item_type = 'avatars'
        @items = @items.avatars
      when 'Background'
        @display_item_type = 'Backgrounds'
        @item_type = 'backgrounds'
        @items = @items.backgrounds
      when 'InWorldObject'
        @display_item_type = 'Objects'
        @item_type = 'in_world_objects'
        @items = @items.in_world_objects
      when 'Prop'
        @display_item_type = 'Props'
        @item_type = 'props'
        @items = @items.props
      else
        raise "Unknown item type"
    end
    
  end

  def show
    @item = MarketplaceItem.find(params[:id])
    @category = @item.marketplace_category
    
    respond_to do |wants|
      wants.html { store_location_if_not_logged_in }
      wants.js
    end
  end

  def search
    @query = params[:q] || ''
    @item_type = params[:type] || ''
    @order = params[:order] || 'date'
    @page = params[:page]
    logger.debug "Order: #{@order}"
    logger.debug "Item Type: #{@item_type}"
    @errors = []
    
    @preview_item_count = 15
    
    case @order
    when 'date'
      @order_fragment = 'created_at DESC'
    when 'date_reverse'
      @order_fragment = 'created_at ASC'
    else
      @errors.push("Unsupported order type: #{@order}")
    end
    
    if @query.empty?
      @errors.push('You must specify a search term.')
    else
      if @item_type.empty?
        @items = MarketplaceItem.active.tagged_with(@query)
      else
        if @errors.empty?
          case @item_type
          when 'avatars'
            @items = MarketplaceItem.avatars.active.tagged_with(@query)
          when 'in_world_objects'
            @items = MarketplaceItem.in_world_objects.active.tagged_with(@query)
          when 'backgrounds'
            @items = MarketplaceItem.backgrounds.active.tagged_with(@query)
          when 'props'
            @items = MarketplaceItem.props.active.tagged_with(@query)
          else
            @errors.push('Unknown item type!')
          end
        end
      end
      if @items
        @items = @items.order(@order_fragment)
        if !@page.nil? && !@page.empty?
          @items = @items.paginate(:page => @page, :per_page => 25)
        end
      end
      
      
      @result_count = @items.count
    end
    
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

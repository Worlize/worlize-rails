class Marketplace::BackgroundsController < ApplicationController
  before_filter :require_user

  def index
    backgrounds = Background.where(['active = ?', 1]).order("created_at DESC").limit(50)
    
    result = backgrounds.map do |background|
      {
        :guid => background.guid,
        :name => background.name,
        :sale_coins => background.sale_coins,
        :sale_bucks => background.sale_bucks,
        :thumbnail => background.image.thumb.url,
        :medium => background.image.medium.url,
        :image => background.image.url
      }
    end
    
    render :json => Yajl::Encoder.encode({
      :success => true,
      :count => result.length,
      :data => result
    })
  end

  def buy
    background = Background.find_by_guid(params[:id])

    if background && background.active

      if background.sale_coins
        currency = :coins
        price = background.sale_coins
        has_sufficient_funds = current_user.coins > price
      elsif background.sale_bucks
        currency = :bucks
        price = background.sale_bucks
        has_sufficient_funds = current_user.bucks > price
      else
        has_sufficient_funds = false
      end

      if !has_sufficient_funds
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => 'Insufficient Funds'
        }) and return
      end

      current_user.debit_account currency => price
      bi = current_user.background_instances.create(:background => background)
      render :json => Yajl::Encoder.encode({
        :success => true,
        :balance => {
          :coins => current_user.coins,
          :bucks => current_user.bucks
        },
        :background_instance => bi.guid
      })

    else
      render :json => Yajl::Encoder.encode({
        :success => false, 
        :description => "Unable to load specified background"
      })
    end
  end
  
  def test
    render :json => Yajl::Encoder.encode({
      :whee => "foo"
    })
  end

end

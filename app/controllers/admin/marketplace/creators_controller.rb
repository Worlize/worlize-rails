class Admin::Marketplace::CreatorsController < ApplicationController
  layout "admin"
  before_filter { |c| c.require_all_permissions(:can_administrate_marketplace) }
    
  def search
    results = []
    if !params[:term].empty?
      query = params[:term];
      query.gsub!('%', '')
      results = MarketplaceCreator.where('display_name LIKE ?', "#{query}%")
    end
    names = results.map do |creator|
      creator.display_name
    end
    render :json => names
  end
  
end

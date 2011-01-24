class Admin::Marketplace::CreatorsController < ApplicationController
  layout "admin"
  
  def search
    if !params[:term].empty?
      query = params[:term];
      query.gsub!('%', '')
      results = MarketplaceCreator.where('display_name LIKE ?', "#{query}%")
      
      render :json => Yajl::Encoder.encode(
        results.map do |creator|
          creator.display_name
        end
      )
    end
  end
end

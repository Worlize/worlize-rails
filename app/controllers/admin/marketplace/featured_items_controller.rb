class Admin::Marketplace::FeaturedItemsController < ApplicationController
  layout "admin"
  before_filter :require_admin
end

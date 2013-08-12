class Admin::Marketplace::TagContextsController < ApplicationController
  layout 'admin'
  before_filter(:only => [:index, :show]) { |c| c.require_all_permissions(:can_administrate_marketplace) }
  before_filter :require_admin, :except => [:index, :show]
  before_filter :find_marketplace_tag_context, :only => [:show, :update, :destroy]

  def index
    @tag_context = MarketplaceTagContext.new
    @tag_contexts = MarketplaceTagContext.all
    
    respond_to do |wants|
      wants.html # index.html.erb
      wants.xml  { render :xml => @tag_contexts }
    end
  end
  
  def show
    respond_to do |wants|
      wants.html # show.html.erb
      wants.xml  { render :xml => @tag_context }
    end
  end
  
  def new
    @tag_context = MarketplaceTagContext.new

    respond_to do |wants|
      wants.html # new.html.erb
      wants.xml  { render :xml => @item }
    end
  end
  
  def create
    @tag_context = MarketplaceTagContext.new(params[:marketplace_tag_context])
    
    respond_to do |wants|
      if @tag_context.save
        wants.html {
          flash[:notice] = 'Tag context created successfully'
          redirect_to admin_marketplace_tag_contexts_url
        }
        wants.xml { render :xml => @tag_context, :status => :created, :location => [:admin, @tag_context] }
      else
        wants.html { render :action => 'new' }
        wants.xml  { render :xml => @tag_context.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    respond_to do |wants|
      if @tag_context.update_attributes(params[:marketplace_tag_context])
        wants.html {
          flash[:notice] = 'Tag context was successfully updated.'
          redirect_to admin_marketplace_tag_contexts_url
        }
        wants.xml  { head :ok }
      else
        wants.html { render :action => 'show' }
        wants.xml  { render :xml => @tag_context.errors, :status => :unprocessable_entity }
      end
    end
  end  

  def destroy
    ActsAsTaggableOn::Tagging.update_all({:context => 'tags'}, {:context => @tag_context.name.downcase})
    @tag_context.destroy

    respond_to do |wants|
      wants.html {
        redirect_to(admin_marketplace_tag_contexts_url)
      }
      wants.xml  { head :ok }
    end
  end

  private
  
  def find_marketplace_tag_context
    @tag_context = MarketplaceTagContext.find(params[:id])
  end

end

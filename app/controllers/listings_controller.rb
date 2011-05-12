class ListingsController < ApplicationController

  before_filter :save_current_path, :only => :show
  before_filter :ensure_authorized_to_view, :only => :show

  before_filter :only => [ :new, :create ] do |controller|
    controller.ensure_logged_in "you_must_log_in_to_create_new_#{params[:type]}"
  end
  
  before_filter :only => [ :edit, :update, :close ] do |controller|
    controller.ensure_logged_in "you_must_log_in_to_view_this_content"
  end
  
  before_filter :only => [ :close ] do |controller|
    controller.ensure_current_user_is_listing_author "only_listing_author_can_close_a_listing"
  end
  
  before_filter :only => [ :edit, :update ] do |controller|
    controller.ensure_current_user_is_listing_author "only_listing_author_can_edit_a_listing"
  end
  
  def index
    redirect_to root
  end
  
  def requests
    params[:listing_type] = "request"
    @to_render = {:action => :index}
    @listing_style = "listing"
    load
  end
  
  def offers
    params[:listing_type] = "offer"
    @to_render = {:action => :index}
    @listing_style = "listing"
    load
  end
  
  # Used to load listings to be shown
  # How the results are rendered depends on 
  # the type of request and if @to_render is set
  def load
    @listing_style = "listing"
    @title = params[:listing_type]
    @to_render ||= {:partial => "listings/listed_listings"}
    @listings = Listing.open.order("created_at DESC").find_with(params, @current_user).paginate(:per_page => 15, :page => params[:page])
    @request_path = request.fullpath
    if request.xhr? && params[:page] && params[:page].to_i > 1
      render :partial => "listings/additional_listings"
    else
      render  @to_render
    end
  end 
  
  # This function renders the map through AJAX request
  def loadmap
    @listing_style = "map"
    respond_to do |format|
      format.js {render :layout => false}
   end
  end

  
  # A (stub) method for serving M data (with locations) as JSON through AJAX-requests.
  def serve_listing_data
    @listing_style = map
    unless params.has_key?(:bounds_sw) && params.has_key?(:bounds_ne) then
      # Send error JSON-message; these params are required
      render :json => { :errors => ["Parameters missing! bounds_sw and bounds_ne are required"]}
    end 
    
    # Bounds of the shown map; query only listings within these bounds (South-West, North-East -coordinates)
    bound_sw_lat, bound_sw_lng = params[:bounds_sw].split('|')
    bound_ne_lat, bound_ne_lng = params[:bounds_ne].split('|')
    
    @listings = Listing.includes(:share_types, :location, :author).open.joins(:location).
                where('locations.latitude <= ? AND locations.longitude <= ? AND locations.latitude >= ? AND locations.longitude >= ?', 
                bound_ne_lat, bound_ne_lng, bound_sw_lat, bound_sw_lng).
                order("created_at DESC").find_with(params, @current_user)

    @render_array = [];
    @listings.each do |listing|
      @render_array[@render_array.length] = render_to_string :partial => "homepage/recent_listing", :locals => {:listing => listing}
    end
    render :json => { :info => @render_array, :data => @listings }
  end
  
  def show
    @listing.increment!(:times_viewed)
  end
  
  def new
    @listing = Listing.new
    @listing.listing_type = params[:type]
    @listing.category = params[:category] || "item"
    1.times { @listing.listing_images.build }
    respond_to do |format|
      format.html
      format.js {render :layout => false}
    end
  end
  
  def create
    @listing = @current_user.create_listing params[:listing]
    if @listing.new_record?
      1.times { @listing.listing_images.build } if @listing.listing_images.empty?
      render :action => :new
    else
      path = new_request_category_path(:type => @listing.listing_type, :category => @listing.category)
      flash[:notice] = ["#{@listing.listing_type}_created_successfully", "create_new_#{@listing.listing_type}".to_sym, path]
      Delayed::Job.enqueue(ListingCreatedJob.new(@listing.id, request.host))
      redirect_to @listing
    end
  end
  
  def edit
    1.times { @listing.listing_images.build } if @listing.listing_images.empty?
  end
  
  def update
    if @listing.update_fields(params[:listing])
      flash[:notice] = "#{@listing.listing_type}_updated_successfully"
      redirect_to @listing
    else
      render :action => :edit
    end    
  end
  
  def close
    @listing.update_attribute(:open, false)
    flash.now[:notice] = "#{@listing.listing_type}_closed"
    respond_to do |format|
      format.html { redirect_to @listing }
      format.js { render :layout => false }
    end
  end
  
  #shows a random listing (that is visible to all)
  def random
    conditions = "open = 1 AND valid_until >= '" + DateTime.now.to_s + "' AND visibility = 'everybody'"
        
    open_listings_ids = Listing.select("id").where(conditions).all
    random_id = open_listings_ids[Kernel.rand(open_listings_ids.length)].id
    #redirect_to listing_path(random_id)
    @listing = Listing.find_by_id(random_id)
    render :action => :show
  end
  
  def ensure_current_user_is_listing_author(error_message)
    @listing = Listing.find(params[:id])
    return if current_user?(@listing.author) || @current_user.is_admin?
    flash[:error] = error_message
    redirect_to @listing and return
  end
  
  private
  
  # Ensure that only users with appropriate visibility settings can view the listing
  def ensure_authorized_to_view
    @listing = Listing.find(params[:id])
    if @current_user
      unless @listing.visible_to?(@current_user)
        flash[:error] = "you_are_not_authorized_to_view_this_content"
        redirect_to root and return
      end
    else
      unless @listing.visibility.eql?("everybody")
        session[:return_to] = request.fullpath
        flash[:warning] = "you_must_log_in_to_view_this_content"
        redirect_to new_session_path and return
      end
    end
  end

end

class InventoriesController < ApplicationController
  protect_from_forgery with: :null_session
  respond_to :json

  before_action :set_inventory_item, except: [:index, :create, :new]

  def index
    @items = Inventory.all || []
  end

  def show
  end

  def new
    @inventory = Inventory.new
  end

    # POST
  # Creates a new Inventory Item
  # Params:
  #   * name - 
  #   * start_date - 
  #   * end_date -
  #   * price - 
  def create
    @inventory = Inventory.new(
      name: params[:name],
      start_date: params[:start_date],
      end_date: params[:end_date],
      price: params[:price],
      object_type: params[:object_type])

    respond_to do |format|
      if @inventory.save
        format.html { redirect_to '/admin/apps/9/index', notice: "Inventory item created." }
        format.json { render json: { success: true, item: inventory }}
      else
        format.html
        format.json { render json: {
          success: false, status: "Error: #{inventory.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

  # GET /inventory(/:id)/inventory
  def get_inventory
    respond_to do |format|
      format.json { render json: { success: true, item: @inventory } }
    end
  end


  # GET /inventory(/:id)/active
  def active
    respond_to do |format|
      format.json { render json: { success: true, active: @inventory.active } }
    end
  end

  # GET /inventory(/:id)/toggle_active
  def toggle_active
    @inventory.active = !@inventory.active

    respond_to do |format|
      if @inventory.save
        format.json { render json: { success: true, active: @inventory.active } }
      else
        format.json { render json: {
          success: false, status: "Error: #{@inventory.errors.full_messages.join(', ')}"
        }}
      end
    end
  end

private

  def set_inventory_item
    @inventory = Inventory.find(params[:id])
  end
end
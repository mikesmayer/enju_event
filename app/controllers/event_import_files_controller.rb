class EventImportFilesController < ApplicationController
  load_and_authorize_resource
  before_filter :prepare_options, only: [:new, :edit]

  # GET /event_import_files
  # GET /event_import_files.json
  def index
    @event_import_files = EventImportFile.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @event_import_files }
    end
  end

  # GET /event_import_files/1
  # GET /event_import_files/1.json
  def show
    if @event_import_file.event_import.path
      unless Rails.application.config_for(:enju_leaf)["uploaded_file"]["storage"] == :s3
        file = @event_import_file.event_import.path
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @event_import_file }
      format.download {
        if Rails.application.config_for(:enju_leaf)["uploaded_file"]["storage"] == :s3
          redirect_to @event_import_file.event_import.expiring_url(10)
        else
          send_file file, filename: @event_import_file.event_import_file_name, type: 'application/octet-stream'
        end
      }
    end
  end

  # GET /event_import_files/new
  # GET /event_import_files/new.json
  def new
    @event_import_file = EventImportFile.new
    @event_import_file.default_library = current_user.profile.library
    @event_import_file.default_event_category = @event_categories.first

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @event_import_file }
    end
  end

  # GET /event_import_files/1/edit
  def edit
  end

  # POST /event_import_files
  # POST /event_import_files.json
  def create
    @event_import_file = EventImportFile.new(event_import_file_params)
    @event_import_file.user = current_user

    respond_to do |format|
      if @event_import_file.save
        if @event_import_file.mode == 'import'
          Resque.enqueue(EventImportFileQueue, @event_import_file.id)
        end
        format.html { redirect_to @event_import_file, notice: t('import.successfully_created', model: t('activerecord.models.event_import_file')) }
        format.json { render json: @event_import_file, status: :created, location: @event_import_file }
      else
        prepare_options
        format.html { render action: "new" }
        format.json { render json: @event_import_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /event_import_files/1
  # PUT /event_import_files/1.json
  def update
    respond_to do |format|
      if @event_import_file.update_attributes(event_import_file_params)
        if @event_import_file.mode == 'import'
          Resque.enqueue(EventImportFileQueue, @event_import_file.id)
        end
        format.html { redirect_to @event_import_file, notice: t('controller.successfully_updated', model: t('activerecord.models.event_import_file')) }
        format.json { head :no_content }
      else
        prepare_options
        format.html { render action: "edit" }
        format.json { render json: @event_import_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_import_files/1
  # DELETE /event_import_files/1.json
  def destroy
    @event_import_file.destroy

    respond_to do |format|
      format.html { redirect_to event_import_files_url }
      format.json { head :no_content }
    end
  end

  private
  def event_import_file_params
    params.require(:event_import_file).permit(
      :event_import, :edit_mode, :user_encoding, :mode,
      :default_library_id, :default_event_category_id
    )
  end

  def prepare_options
    @libraries = Library.all
    @event_categories = EventCategory.order(:position)
  end
end

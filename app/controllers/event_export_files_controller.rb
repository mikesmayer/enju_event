class EventExportFilesController < ApplicationController
  load_and_authorize_resource

  # GET /event_export_files
  # GET /event_export_files.json
  def index
    @event_export_files = EventExportFile.order('id DESC').page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @event_export_files }
    end
  end

  # GET /event_export_files/1
  # GET /event_export_files/1.json
  def show
    if @event_export_file.event_export.path
      unless Rails.application.config_for(:enju_leaf)["uploaded_file"]["storage"] == :s3
        file = @event_export_file.event_export.path
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @event_export_file }
      format.download {
        if Rails.application.config_for(:enju_leaf)["uploaded_file"]["storage"] == :s3
          redirect_to @event_export_file.event_export.expiring_url(10)
        else
          send_file file, filename: @event_export_file.event_export_file_name, type: 'application/octet-stream'
        end
      }
    end
  end

  # GET /event_export_files/new
  # GET /event_export_files/new.json
  def new
    @event_export_file = EventExportFile.new
    @event_export_file.user = current_user

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @event_export_file }
    end
  end

  # GET /event_export_files/1/edit
  def edit
  end

  # POST /event_export_files
  # POST /event_export_files.json
  def create
    @event_export_file = EventExportFile.new(event_export_file_params)
    @event_export_file.user = current_user

    respond_to do |format|
      if @event_export_file.save
        if @event_export_file.mode == 'export'
          Resque.enqueue(EventExportFileQueue, @event_export_file.id)
        end
        format.html { redirect_to @event_export_file, notice: t('export.successfully_created', model: t('activerecord.models.event_export_file')) }
        format.json { render json: @event_export_file, status: :created, location: @event_export_file }
      else
        format.html { render action: "new" }
        format.json { render json: @event_export_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /event_export_files/1
  # PUT /event_export_files/1.json
  def update
    respond_to do |format|
      if @event_export_file.update_attributes(event_export_file_params)
        if @event_export_file.mode == 'export'
          EventExportFileQueue.perform(@event_export_file.id)
        end
        format.html { redirect_to @event_export_file, notice: t('controller.successfully_updated', model: t('activerecord.models.event_export_file')) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @event_export_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_export_files/1
  # DELETE /event_export_files/1.json
  def destroy
    @event_export_file.destroy

    respond_to do |format|
      format.html { redirect_to event_export_files_url }
      format.json { head :no_content }
    end
  end

  private
  def event_export_file_params
    params.require(:event_export_file).permit(:mode)
  end
end

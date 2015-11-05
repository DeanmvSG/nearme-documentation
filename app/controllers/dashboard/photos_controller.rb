class Dashboard::PhotosController < Dashboard::AssetsController

  before_action :get_image, only: :create

  def create
    @photo = Photo.new
    @photo.owner = @owner
    @photo.owner_type ||= @owner_type
    @photo.image = @image
    @photo.creator_id = current_user.id
    if @photo.save
      render :text => {
        :id => @photo.id,
        :transactable_id => @photo.owner_id,
        :thumbnail_dimensions => 'Project' === @owner_type ? @photo.image.thumbnail_dimensions[:project_thumbnail] : @photo.image.thumbnail_dimensions[:medium],
        :url => 'Project' === @owner_type ? @photo.image_url(:project_thumbnail) : @photo.image_url(:medium) ,
        :destroy_url => destroy_space_wizard_photo_path(@photo),
        :resize_url =>  edit_dashboard_photo_path(@photo)
      }.to_json,
      :content_type => 'text/plain'
    else
      render :text => [{:error => @photo.errors.full_messages}], :content_type => 'text/plain', :status => 422
    end
  end

  def edit
    @photo = current_user.photos.find(params[:id])
    if request.xhr?
      render partial: 'dashboard/photos/resize_form', :locals => { :form_url => dashboard_photo_path(@photo), :object => @photo.image, :object_url => @photo.image_url(:original) }
    end
  end

  def update
    @photo = current_user.photos.find(params[:id])
    @photo.image_transformation_data = { :crop => params[:crop], :rotate => params[:rotate] }
    if @photo.save
      render partial: 'dashboard/photos/resize_succeeded'
    else
      render partial: 'dashboard/photos/resize_form', :locals => { :form_url => dashboard_photo_path(@photo), :object => @photo.image, :object_url => @photo.image_url(:original) }
    end
  end

  def destroy
    @photo = current_user.photos.find(params[:id])
    if @photo.destroy
      render :text => { success: true, id: @photo.id }, :content_type => 'text/plain'
    else
      render :text => { :errors => @photo.errors.full_messages }, :status => 422, :content_type => 'text/plain'
    end
  end

  private

  def get_image
    @image = @listing_params[:photos_attributes]["0"][:image]
  end
end

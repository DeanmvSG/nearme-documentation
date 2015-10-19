class InstanceAdmin::Projects::ProjectsController < InstanceAdmin::Projects::BaseController
  defaults resource_class: Project, collection_name: 'projects', instance_name: 'project', route_prefix: 'instance_admin'

  def index
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    @project.update_columns(params[:project])
    flash[:success] = "#{@project.name} has been updated successfully"
    redirect_to instance_admin_projects_projects_path
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    flash[:success] = "#{@project.name} has been deleted"
    redirect_to instance_admin_projects_projects_path
  end

  def restore
    @project = Project.with_deleted.find(params[:id])
    @project.restore
    flash[:success] = "#{@project.name} has been restored"
    redirect_to instance_admin_projects_projects_path
  end

  protected

  def collection_search_fields
    %w(name)
  end

  def collection
    if @projects.blank?
      @project_search_form = InstanceAdmin::ProjectSearchForm.new
      @project_search_form.validate(params)
      @projects = SearchService.new(Project.order('created_at DESC').with_deleted).search(@project_search_form.to_search_params).paginate(page: params[:page])
    end

    @projects
  end
end
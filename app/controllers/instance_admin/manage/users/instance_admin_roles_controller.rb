class InstanceAdmin::Manage::Users::InstanceAdminRolesController < InstanceAdmin::Manage::BaseController

  def index
    redirect_to instance_admin_manage_users_path
  end

  def create
    @instance_admin_role = InstanceAdminRole.new(params[:instance_admin_role])
    @instance_admin_role.instance_id = platform_context.instance.id
    if @instance_admin_role.save

      flash[:success] = t('flash_messages.instance_admin.users.instance_admin_roles.role_added')
      redirect_to instance_admin_manage_users_path
    else
      render "instance_admin/manage/users/index"
    end
  end

  def update
    @instance_admin_role = platform_context.instance.instance_admin_roles.find(params[:id])
    @instance_admin_role.update_attributes(params[:instance_admin_role]) if only_updates_permission?
    render :nothing => true
  end

  def destroy
    # scoping to instance guarantess that global role will not be deleted
    @instance_admin_role = platform_context.instance.instance_admin_roles.find(params[:id])
    @instance_admin_role.destroy
    flash[:deleted] = t('flash_messages.instance_admin.users.instance_admin_roles.role_deleted')
    redirect_to instance_admin_manage_users_path
  end

  private

  def only_updates_permission?
    params[:instance_admin_role].keys.all? { |iar| iar.include?("permission_") }
  end

  def permitting_controller_class
    'manage'
  end
end

class InstanceAdmin::Manage::Admins::InstanceAdminsController < InstanceAdmin::Manage::BaseController

  skip_before_filter :check_if_locked

  def index
    redirect_to instance_admin_manage_admins_path
  end

  def create
    @user = User.where(:email => params[:email]).first
    if @user
      if InstanceAdmin.where(:user_id => @user.id).first.present?
        flash[:warning] = "User with email #{@user.email} has already been added as admin"
      else
        InstanceAdmin.create(:user_id => @user.id)
        flash[:success] = "User with email #{@user.email} has been successfully added as admin"
      end
      redirect_to instance_admin_manage_admins_path
    else
      flash[:error] = "Unfortunately we could not find user with email \"#{params[:email]}\""
      render "instance_admin/manage/admins/index"
    end
  end

  def update
    @instance_admin = InstanceAdmin.find(params[:id])
    unless @instance_admin.instance_owner
      @instance_admin.update_attribute(:instance_admin_role_id, InstanceAdminRole.find(params[:instance_admin_role_id]).id)
    end
    render :nothing => true
  end

  def destroy
    @instance_admin = InstanceAdmin.find(params[:id])
    if @instance_admin.instance_owner
      flash[:error] = 'Instance owner cannot be deleted'
    else
      @instance_admin.destroy
      flash[:deleted] = "#{@instance_admin.name} is no longer an instance admin"
    end
    redirect_to instance_admin_manage_admins_path
  end

  private

  def permitting_controller_class
    'manage'
  end
end

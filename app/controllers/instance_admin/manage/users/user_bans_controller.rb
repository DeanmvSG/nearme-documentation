class InstanceAdmin::Manage::Users::UserBansController < InstanceAdmin::Manage::BaseController

  def create
    @user_ban = UserBan.new
    @user_ban.user_id = params[:user_id]
    @user_ban.creator_id = current_user.id
    if @user_ban.save
      flash[:success] = t('flash_messages.instance_admin.manage.users.user_ban.created')
    else
      flash[:error] = t('flash_messages.instance_admin.manage.users.user_ban.not_created')
    end
    redirect_to instance_admin_manage_users_path
  end

  private

  def permitting_controller_class
    'manage'
  end

end

class InstanceAdmin::Manage::UsersController < InstanceAdmin::Manage::BaseController

  skip_before_filter :check_if_locked

  def index
    @user = User.new
    @instance_admin = InstanceAdmin.new
  end

  def create
    @user = User.new(params[:user])
    @user.skip_password = true
    if @user.save
      InstanceAdmin.create(:user_id => @user.id)
      PostActionMailer.enqueue.created_by_instance_admin(@user, current_user)
      flash[:success] = "User has been successfully created"
      redirect_to instance_admin_manage_users_path
    else
      render :index
    end
  end

end

class InstanceAdmin::Manage::UsersController < InstanceAdmin::Manage::BaseController

  skip_before_filter :check_if_locked

  def index
    @user = User.new
    @instance_admin = InstanceAdmin.new
  end

  def create
    @user = User.new(user_params)
    @user.skip_password = true
    if @user.save
      InstanceAdmin.create(:user_id => @user.id)
      WorkflowStepJob.perform(WorkflowStep::SignUpWorkflow::CreatedByAdmin, @user.id, current_user.id)
      flash[:success] = "User has been successfully created"
      redirect_to instance_admin_manage_users_path
    else
      render :index
    end
  end

  private

  def user_params
    params.require(:user).permit(secured_params.user)
  end
end

class Admin::InstancesController < Admin::ResourceController
  before_filter -> { PlatformContext.current = PlatformContext.new(Instance.find(params[:id])) }, only: [:edit, :update, :destroy, :show]

  def update
    @instance = Instance.find(params[:id])
    if @instance.update_attributes(instance_params)
      flash[:success] = 'Instance was successfully updated.'
      redirect_to admin_instance_path(@instance)
    else
      flash.now[:error] = @instance.errors.full_messages.to_sentence
      render 'edit'
    end
  end

  private

  def instance_params
    params.require(:instance).permit(secured_params.instance)
  end
end

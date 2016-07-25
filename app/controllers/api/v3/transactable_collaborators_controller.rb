module Api
  class V3::TransactableCollaboratorsController < BaseController
    skip_before_filter :require_authorization
    before_filter :find_transactable

    def create
      @transactable_collaborator = @transactable.transactable_collaborators.build
      if is_creator?
        user = User.find_by(id: params[:user_id]) || User.find_by(email: params[:email])
        @transactable_collaborator.user = user
        if @transactable_collaborator.valid?
          @transactable_collaborator.approved_by_owner_at = Time.zone.now
          @transactable_collaborator.save!
          WorkflowStepJob.perform(WorkflowStep::CollaboratorWorkflow::CollaboratorAddedByProjectOwner, @transactable_collaborator.id)
          render json: ApiSerializer.serialize_object(@transactable_collaborator)
        else
          render json: ApiSerializer.serialize_errors(@transactable_collaborator.errors)
        end
        # someone asks for permission to become collaborator
      else
        @transactable_collaborator.user = current_user
        @transactable_collaborator.approved_by_user_at = Time.zone.now
        @transactable_collaborator.save!
        WorkflowStepJob.perform(WorkflowStep::CollaboratorWorkflow::CollaboratorPendingApproval, @transactable_collaborator.id)
        render json: ApiSerializer.serialize_object(@transactable_collaborator)
      end
    end

    def accept
      if is_creator?
        @transactable_collaborator = @transactable.transactable_collaborators.find(params[:id])
        @transactable_collaborator.approve_by_owner!
        WorkflowStepJob.perform(WorkflowStep::CollaboratorWorkflow::CollaboratorApproved, @transactable_collaborator.id)
        render json: ApiSerializer.serialize_object(@transactable_collaborator)
      else
        @transactable_collaborator = @transactable.transactable_collaborators.for_user(current_user).find(params[:id])
        @transactable_collaborator.approve_by_user!
        render json: ApiSerializer.serialize_object(@transactable_collaborator)
      end
    end

    def destroy
      if is_creator?
        @transactable_collaborator = @transactable.transactable_collaborators.find(params[:id])
        WorkflowStepJob.perform(WorkflowStep::CollaboratorWorkflow::CollaboratorDeclined, @transactable_collaborator.transactable_id, @transactable_collaborator.user_id)
        @transactable_collaborator.destroy
        render nothing: true, status: 204
      else
        @transactable_collaborator = @transactable.transactable_collaborators.for_user(current_user).find(params[:id]).destroy
        WorkflowStepJob.perform(WorkflowStep::CollaboratorWorkflow::CollaboratorHasQuit, @transactable_collaborator.transactable_id, @transactable_collaborator.user_id)
        @transactable_collaborator.destroy
        render nothing: true, status: 204
      end
    end

    protected

    def find_transactable
      @transactable = Transactable.find(params[:transactable_id])
    end

    def is_creator?
      @transactable.creator.id == current_user.id
    end

  end
end

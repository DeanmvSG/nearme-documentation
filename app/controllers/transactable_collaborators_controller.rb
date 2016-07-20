class TransactableCollaboratorsController < ApplicationController
  layout :dashboard_or_community_layout

  before_filter :find_transactable, except: [:create]
  before_action :authenticate_user!

  def create
    @transactable = Transactable.seek_collaborators.find(params[:transactable_id] || params[:listing_id])
    transactable_collaborator = @transactable.transactable_collaborators.create(user: current_user, approved_by_user_at: Time.now)
    @collaborators_count = @transactable.reload.transactable_collaborators.approved.count
    WorkflowStepJob.perform(WorkflowStep::CollaboratorWorkflow::CollaboratorPendingApproval, transactable_collaborator.id)
    respond_to do |format|
      format.js { render :collaborators_button }
    end
  end

  def destroy
    @transactable.transactable_collaborators.for_user(current_user).destroy_all
    @collaborators_count = @transactable.reload.transactable_collaborators.approved.count
    respond_to do |format|
      format.js { render :collaborators_button }
      format.html { redirect_to profile_path(current_user, anchor: :transactables), notice: t('collaboration_cancelled') }
    end
  end

  def accept
    transactable_collaboration = @transactable.transactable_collaborators.for_user(current_user).find(params[:id])
    transactable_collaboration.update_attribute(:user_id, current_user.id) unless transactable_collaboration.approved_by_owner_at.present?
    transactable_collaboration.approve_by_user!
    redirect_to profile_path(current_user, anchor: :transactables), notice: t('collaboration_accepted')
  end

  protected

  def find_transactable
    @transactable = Transactable.find(params[:transactable_id] || params[:listing_id])
  end

end


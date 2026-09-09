class Api::V1::Accounts::PriorityGroupsController < Api::V1::Accounts::BaseController
  before_action :set_account
  before_action :fetch_priority_group, only: [:update, :destroy]
  before_action :check_authorization

  def index
    render json: @account.priority_groups.select(:id, :name)
  end

  def create
    @priority_group = @account.priority_groups.create!(priority_group_params)
    render json: @priority_group, only: [:id, :name]
  end

  def update
    @priority_group.update!(priority_group_params)
    render json: @priority_group, only: [:id, :name]
  end

  def destroy
    @priority_group.destroy!
    head :ok
  end

  private

  def set_account
    @account = current_account
  end

  def fetch_priority_group
    @priority_group = @account.priority_groups.find(params[:id])
  end

  def priority_group_params
    params.require(:priority_group).permit(:name)
  end
end

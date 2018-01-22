class GroupAPI
  include Base

  authenticate :join, :leave

  def index
    groups = Group.with_categories.active.publics.order(name: :asc).limit(20)
    render(groups, 'groups/index')
  end

  def join
    if current_group.public?
      current_group.join!(current_user)
      responds('ok')
    else
      not_found
    end
  end

  def leave
    current_group.leave!(current_user)
    responds('ok')
  end

  private

  def current_group
    @group ||= Group.find(params[:group_id])
  end
end

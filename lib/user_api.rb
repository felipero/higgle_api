class UserAPI
  include Base

  def show
    render(User.find(params[:user_id]), 'users/login')
  end

  def find_by_email
    user = User.find_by(email: params[:email])
    return not_found unless user.present?
    render(user, 'users/login')
  end
end

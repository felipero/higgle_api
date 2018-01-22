module Base
  extend ActiveSupport::Concern

  VIEW_PATH = 'app/views/api'

  def call(action, params = {})
    @_params = params
    send(get_action_name(action))
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def get_action_name(action)
    return action unless authenticated_actions.include? action
    authorize_user || action
  end

  def current_user
    @user ||= User.find_by(auth_token: params['auth_token'])
  end

  private

  def params
    @_params.with_indifferent_access || {}
  end

  def authorize_user
    token = params['auth_token']
    return :not_found if current_user.blank? || token.blank?
    nil
  end

  def render(object, template, format = :json, status = 200, content_type = 'application/json')
    responds Rabl.render(object, template, view_path: VIEW_PATH, format: format, locals: { current_user: current_user }), status, content_type
  end

  def render_with_locals(object, template, format = :json, status = 200, content_type = 'application/json', locals)
    responds Rabl.render(object, template, view_path: VIEW_PATH, format: format, locals: locals.merge({ current_user: current_user })), status, content_type
  end

  def not_found(_params = nil)
    responds({ message: I18n.t('api.commom.resource_not_found') }.to_json, 404)
  end

  def internal_error(_params = nil)
    responds({ message: I18n.t('api.commom.internal_server_error') }.to_json, 501)
  end

  def responds(body, status = 200, content_type = 'application/json')
    [
      status,
      { 'Content-Type' => content_type },
      [body]
    ]
  end

  included do
    class_attribute :authenticated_actions
    self.authenticated_actions ||= []
  end

  class_methods do
    def authenticate(*actions)
      self.authenticated_actions = actions
    end
  end
end

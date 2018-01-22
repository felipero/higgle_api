class HiggleAPI
  include Base

  authenticate :create, :join, :higgles_created_by_user

  def login
    return render(current_user, 'users/login') if current_user.present?
    not_found
  end

  def create
    return internal_error unless params['higgle_price'].present? && params['quantity'].present?
    higgle = create_higgle
    process_address!(params['address_line'])
    return credit_card_error unless process_billing!(params['last4_credit_card'])
    order = create_order!(higgle)
    process_higgle(order, higgle)
    responds({ slug: higgle.slug }.to_json)
  rescue Stripe::CardError
    return credit_card_error
  end

  def index
    higgles = Higgle.running.order(updated_at: :desc)
    render_with_locals(higgles, 'higgles/index', locals: { comments_hash: comments_hash(higgles) })
  end

  def join
    higgle = Higgle.running.find(params[:higgle_id])
    order = create_order!(higgle)
    process_higgle(order, higgle)
  rescue Stripe::CardError
    return credit_card_error
  end

  def higgles_created_by_user
    higgles = current_user.created_higgles.order(end_date: :desc)
    render_with_locals(higgles, 'higgles/index', locals: { comments_hash: comments_hash(higgles) })
  end

  def for_category
    category = Category.find(params['category_id'])
    higgles = Higgle.from_category_by_unique_products(category).order(end_date: :desc).page(params[:page].to_i).per(params[:per_page].to_i)
    render_with_locals(higgles, 'higgles/index', locals: { comments_hash: comments_hash(higgles) })
  end

  def for_group
    group = Group.find params['group_id']
    higgles = group.higgles.order(end_date: :desc)
    render_with_locals(higgles, 'higgles/index', locals: { comments_hash: comments_hash(higgles) })
  end

  private

  def process_higgle(order, higgle)
    if order.persisted?
      responds({ id: higgle.id }.to_json)
    else
      responds({ errors: order.errors.messages }.to_json, 403)
    end
  end

  def create_higgle
    product = Product.find(params['product_id'])
    Higgle.new(product: product,
               merchant: product.merchant,
               group: Group.find_by_id(params['group_id']),
               creator: current_user,
               categories: product.categories,
               quantity_sold: params['quantity'].to_i,
               higgle_price: params['higgle_price'],
               buy_it_now: false)
  end

  def create_order!(higgle)
    raise ActiveRecord::RecordNotFound if current_user.blank?
    order = Order.build_order(address: current_user.address, quantity: params['quantity'].to_i, user: current_user, higgle: higgle)
    OrderTransaction.charge!(order, false)
    order
  end

  def process_address!(address_line)
    if address_line.present?
      address = check_address
      return if address.equals(params['address_line'], params['address_city'], params['address_state'], params['address_zipcode'])
      address.address_line = params['address_line']
      address.city = params['address_city']
      address.state = params['address_state']
      address.zip_code = params['address_zipcode']
    end
  end

  def check_address
    address = current_user.address
    return address if address.present?
    address = Address.new(addressable: current_user, address_line: params['address_line'], city: params['address_city'], state: params['address_state'], zip_code: params['address_zipcode'], addressable_type: 'User')
    current_user.address = address
    address
  end

  def process_billing!(last4_credit_card)
    if last4_credit_card.present?
      return if billing_equal?
      return current_user.update_card(card_params)
    end
  end

  def billing_equal?
    current_user.last4_credit_card == params['last4_credit_card'].last(4) &&
      current_user.credit_card_holder_name == params['credit_card_holder_name'] &&
      current_user.credit_card_expiration_month == params['credit_card_expiration_month'] &&
      current_user.credit_card_expiration_year == params['credit_card_expiration_year']
  end

  def card_params
    card_params = {
      credit_card_expiration_month: params['credit_card_expiration_month'],
      credit_card_expiration_year: params['credit_card_expiration_year'],
      credit_card_holder_name: params['credit_card_holder_name'],
      last4_credit_card: params['last4_credit_card'],
      cvc: params['cvc']
    }
    card_params
  end

  def credit_card_error
    responds({ message: I18n.t('api.commom.internal_server_error') }.to_json, 403)
  end

  def comments_hash(higgles)
    comments_hash = {}
    higgles.each { |higgle| comments_hash[higgle.id] = higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json } }
    comments_hash
  end
end

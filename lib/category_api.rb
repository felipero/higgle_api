class CategoryAPI
  include Base

  authenticate :follow, :unfollow

  def index
    categories = Category.top_categories.with_higgles_or_products.order(higgles_count: :desc).limit(20)
    render(categories, 'categories/index')
  end

  def follow
    current_user.follow_category(current_category)
    responds('ok')
  end

  def unfollow
    current_user.unfollow_category(current_category)
    responds('ok')
  end

  private

  def current_category
    @category ||= Category.find(params['category_id'])
  end
end

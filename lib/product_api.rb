class ProductAPI
  include Base

  authenticate :liked, :like

  def index
    products = Product.active.featured.includes(:pictures, :categories).page(params['page'].to_i).per(params['per_page'].to_i)
    categories_hash = {}
    products.each { |product| categories_hash[product.id] = product.categories.map { |cat| { id: cat.id, name: cat.name }.to_json } }
    render_with_locals(products, 'products/index', locals: { product_count: Product.count, categories_hash: categories_hash })
  end

  def liked
    products = current_user.products_liked.popular.page(params['page'].to_i).per(params['per_page'].to_i)

    categories_hash = {}
    products.each { |product| categories_hash[product.id] = product.categories.map { |cat| { id: cat.id, name: cat.name }.to_json } }

    render_with_locals(products, 'products/index', locals: { product_count: Product.count, categories_hash: categories_hash })
  end

  def like
    current_user.like_product!(product)
    responds('ok')
  end

  def dislike
    current_user.dislike_product!(product)
    responds('ok')
  end

  private

  def product
    Product.find(params[:product_id])
  end
end

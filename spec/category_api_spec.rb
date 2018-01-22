describe 'Category API' do
  let(:category_api) { CategoryAPI.new }

  describe '#index' do
    context 'when having no categories' do
      context 'with no products' do
        it 'return an empty array' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq ['[]']
        end
      end
    end

    context 'when having categories' do
      let!(:category) { Fabricate :category }

      context 'with no products and no higgles' do
        it 'returns no categories' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq ['[]']
        end
      end

      context 'with higgle and no product - this logic seems to make no sense, since we cannot have product without categories and no higgle without product either' do
        let(:category) { Fabricate :category }
        let(:product) { Fabricate :product, categories: [category] }
        let!(:higgle) { Fabricate :higgle, product: product, categories: [category] }

        it 'returns the category with higgle' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
            [
              {
                id: category.id,
                name: category.name,
                products: category.products.map { |product| { product_id: product.id, product_image: product.picture.big.url } },
                following_count: category.users.count,
                higgles_count: category.higgles_count,
                horizontal_picture: category.horizontal_picture.big.url
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'having two categories with different higgles_count' do
        let(:category) { Fabricate :category }
        let(:other_category) { Fabricate :category }

        let(:product) { Fabricate :product, categories: [category] }
        let(:other_product) { Fabricate :product, categories: [other_category] }

        before do
          2.times { Fabricate(:higgle, product: other_product) }
          Fabricate(:higgle, product: product)
        end

        it 'returns the category with higgle' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
            [
              {
                id: other_category.id,
                name: other_category.name,
                products: other_category.products.map { |product| { product_id: product.id, product_image: product.picture.big.url } },
                following_count: other_category.users.count,
                higgles_count: other_category.higgles_count,
                horizontal_picture: other_category.horizontal_picture.big.url
              },
              {
                id: category.id,
                name: category.name,
                products: category.products.map { |product| { product_id: product.id, product_image: product.picture.big.url } },
                following_count: category.users.count,
                higgles_count: category.higgles_count,
                horizontal_picture: other_category.horizontal_picture.big.url
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'with one product' do
        let!(:product) { Fabricate :product, categories: [category] }

        it 'return all categories and the image of product' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
              [
                {
                  id: category.id,
                  name: category.name,
                  products: category.products.map { |product| { product_id: product.id, product_image: product.picture.big.url } },
                  following_count: category.users.count,
                  higgles_count: category.higgles_count,
                  horizontal_picture: category.horizontal_picture.big.url
                }
              ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'with two products' do
        let!(:product) { Fabricate :product, categories: [category], created_at: 1.month.ago }
        let!(:other_product) { Fabricate :product, categories: [category], created_at: 1.month.from_now }

        it 'returns all categories having products ordered by popular and created at' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
              [
                {
                  id: category.id,
                  name: category.name,
                  products: [
                    { product_id: other_product.id, product_image: other_product.picture.big.url },
                    { product_id: product.id, product_image: product.picture.big.url }
                  ],
                  following_count: category.users.count,
                  higgles_count: category.higgles_count,
                  horizontal_picture: category.horizontal_picture.big.url
                }
              ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'with followers and users' do
        let(:user) { Fabricate :user }
        let(:category) { Fabricate :category, users: [user] }
        let(:product) { Fabricate :product, categories: [category] }
        let!(:higgle) { Fabricate :higgle, product: product }

        it 'returns the correct counting' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
            [
              {
                id: category.id,
                name: category.name,
                products: category.products.map { |product| { product_id: product.id, product_image: product.picture.big.url } },
                following_count: 1,
                higgles_count: 1,
                horizontal_picture: category.horizontal_picture.big.url
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end
    end

    context 'the last 3 most popular' do
      let!(:category) { Fabricate :category }
      let(:merchant) { Fabricate :merchant }

      context 'with three products, and the first as most popular' do
        let!(:first) { Fabricate(:product, merchant: merchant, categories: [category]) }
        let!(:second) { Fabricate(:product, merchant: merchant, categories: [category]) }
        let!(:third) { Fabricate(:product, merchant: merchant, higgles: [], categories: [category]) }
        before do
          2.times { Fabricate(:higgle, product: first) }
          Fabricate(:higgle, product: second)
        end
        it 'returns the most popular products' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
            [
              {
                id: category.id,
                name: category.name,
                products: [
                  { product_id: first.id, product_image: first.picture.big.url },
                  { product_id: second.id, product_image: second.picture.big.url },
                  { product_id: third.id, product_image: third.picture.big.url }
                ],
                following_count: category.users.count,
                higgles_count: category.higgles_count,
                horizontal_picture: category.horizontal_picture.big.url
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'with three products, and the third as most popular and the first as popular' do
        let!(:first) { Fabricate(:product, merchant: merchant, categories: [category]) }
        let!(:second) { Fabricate(:product, merchant: merchant, categories: [category]) }
        let!(:third) { Fabricate(:product, merchant: merchant, categories: [category]) }
        before do
          2.times { Fabricate(:higgle, product: first) }
          5.times { Fabricate(:higgle, product: third) }
          Fabricate(:higgle, product: second)
        end
        it 'returns the most popular products' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
            [
              {
                id: category.id,
                name: category.name,
                products: [
                  { product_id: third.id, product_image: third.picture.big.url },
                  { product_id: first.id, product_image: first.picture.big.url },
                  { product_id: second.id, product_image: second.picture.big.url }
                ],
                following_count: category.users.count,
                higgles_count: category.higgles_count,
                horizontal_picture: category.horizontal_picture.big.url
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'with four products, and the third as most popular and the first as popular and the forth as the most popular' do
        let!(:first) { Fabricate(:product, merchant: merchant, categories: [category]) }
        let!(:second) { Fabricate(:product, merchant: merchant, categories: [category]) }
        let!(:third) { Fabricate(:product, merchant: merchant, categories: [category]) }
        let!(:forth) { Fabricate(:product, merchant: merchant, categories: [category]) }
        before do
          2.times { Fabricate(:higgle, product: first) }
          5.times { Fabricate(:higgle, product: third) }
          12.times { Fabricate(:higgle, product: forth) }
          Fabricate(:higgle, product: second)
        end
        it 'returns the most popular products' do
          params = { page: nil, per_page: nil }
          response = category_api.call(:index, params)
          expected_return =
            [
              {
                id: category.id,
                name: category.name,
                products: [
                  { product_id: forth.id, product_image: forth.picture.big.url },
                  { product_id: third.id, product_image: third.picture.big.url },
                  { product_id: first.id, product_image: first.picture.big.url }
                ],
                following_count: category.users.count,
                higgles_count: category.higgles_count,
                horizontal_picture: category.horizontal_picture.big.url
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end
    end
  end

  describe '#follow' do
    let(:category) { Fabricate :category }
    let(:user) { Fabricate :user }

    context 'when the user is not following the category' do
      it 'follows the category' do
        Fabricate(:user, categories: [category]) # other user
        params = { 'category_id' => category.id, 'auth_token' => user.auth_token }
        response = category_api.call(:follow, params)
        expect(response).to be_200
        expect(User.find(user.id).categories).to match_array [category]
      end
    end

    context 'without token' do
      it 'responds 404' do
        params = { 'category_id' => category.id }
        response = category_api.call(:follow, params)
        expect(response).to be_404
      end
    end

    context 'without category' do
      it 'responds 404' do
        params = { 'auth_token' => user.auth_token }
        response = category_api.call(:follow, params)
        expect(response).to be_404
      end
    end
  end

  describe '#unfollow' do
    let(:category) { Fabricate(:category) }
    let(:user) { Fabricate(:user) }
    let(:params) { { 'auth_token' => user.auth_token } }

    context 'unauthenticated' do
      it 'responds 404' do
        response = category_api.call(:unfollow, { 'category_id' => category.to_param })
        expect(response).to be_404
      end
    end

    context 'authenticated' do
      context 'when category not found' do
        it 'responds 404' do
          response = category_api.call(:unfollow, params.merge('category_id' => '999'))
          expect(response).to be_404
        end
      end

      context 'when category found' do
        context 'and user follows category' do
          it 'unfollows category' do
            CategoriesUser.create!(user: user, category: category)
            response = category_api.call(:unfollow, params.merge('category_id' => category.id))
            expect(response).to be_200
            expect(user.reload.categories).not_to include(category)
          end
        end

        context 'and user does not follows category' do
          it 'responds ok doing nothing' do
            response = category_api.call(:unfollow, params.merge('category_id' => category.id))
            expect(response).to be_200
            expect(user.reload.categories).not_to include(category)
          end
        end
      end
    end
  end
end

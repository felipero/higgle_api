describe 'Product API' do
  let(:product_api) { ProductAPI.new }
  let!(:product) { Fabricate :product }

  describe '#index' do
    context 'with one product' do
      let!(:product) { Fabricate :product, featured: true }

      context 'and no pagination' do
        it 'returns the product' do
          params = { page: nil, per_page: nil }
          product_json = product_api.call(:index, params)
          expect(product_json[0]).to eq 200
          expect(product_json[1]).to eq({ 'Content-Type' => 'application/json' })
          body_parsed = JSON.parse(product_json[2][0])
          expect(body_parsed[0]['id']).to eq product.id
          expect(body_parsed[0]['title']).to eq product.title
          expect(body_parsed[0]['msrp_price']).to eq product.msrp_price
          expect(body_parsed[0]['unfair_rate']).to eq product.unfair_rate
          expect(body_parsed[0]['people_needed']).to eq product.people_needed_hash.to_json
          expect(body_parsed[0]['description']).to eq product.description
          expect(body_parsed[0]['image']).to eq product.picture.big.url
          expect(body_parsed[0]['categories']).to match_array product.categories.map { |category| { id: category.id, name: category.name }.to_json }
          expect(body_parsed[0]['products_count']).to eq Product.count
        end
      end

      context 'and paginating' do
        it 'returns the product' do
          params = { page: 1, per_page: 1 }
          product_json = product_api.call(:index, params)
          body_parsed = JSON.parse(product_json[2][0])
          expect(body_parsed[0]['id']).to eq product.id
          expect(body_parsed[0]['title']).to eq product.title
          expect(body_parsed[0]['msrp_price']).to eq product.msrp_price
          expect(body_parsed[0]['unfair_rate']).to eq product.unfair_rate
          expect(body_parsed[0]['people_needed']).to eq product.people_needed_hash.to_json
          expect(body_parsed[0]['description']).to eq product.description
          expect(body_parsed[0]['image']).to eq product.picture.big.url
          expect(body_parsed[0]['categories']).to match_array product.categories.map { |category| { id: category.id, name: category.name }.to_json }
          expect(body_parsed[0]['products_count']).to eq Product.count
        end
      end
    end

    context 'with two products' do
      let!(:product) { Fabricate :product, categories: Fabricate.times(3, :category), featured: true }
      let!(:other_product) { Fabricate :product, featured: true }

      context 'no pagination' do
        it 'returns the products, newest and popular first' do
          params = { 'page' => nil, 'per_page' => nil }
          product_json = product_api.call(:index, params)
          expect(product_json[0]).to eq 200
          expect(product_json[1]).to eq({ 'Content-Type' => 'application/json' })
          body_parsed = JSON.parse(product_json[2][0])
          expect(body_parsed[0]['id']).to eq other_product.id
          expect(body_parsed[0]['title']).to eq other_product.title
          expect(body_parsed[0]['msrp_price']).to eq other_product.msrp_price
          expect(body_parsed[0]['unfair_rate']).to eq other_product.unfair_rate
          expect(body_parsed[0]['people_needed']).to eq other_product.people_needed_hash.to_json
          expect(body_parsed[0]['description']).to eq other_product.description
          expect(body_parsed[0]['categories']).to match_array other_product.categories.map { |category| { id: category.id, name: category.name }.to_json }
          expect(body_parsed[0]['products_count']).to eq Product.count

          expect(body_parsed[1]['id']).to eq product.id
          expect(body_parsed[1]['title']).to eq product.title
          expect(body_parsed[1]['msrp_price']).to eq product.msrp_price
          expect(body_parsed[1]['unfair_rate']).to eq product.unfair_rate
          expect(body_parsed[1]['people_needed']).to eq product.people_needed_hash.to_json
          expect(body_parsed[1]['description']).to eq product.description
          expect(body_parsed[1]['categories']).to match_array product.categories.map { |category| { id: category.id, name: category.name }.to_json }
          expect(body_parsed[1]['products_count']).to eq Product.count
        end
      end

      context 'with two products and one per page' do
        context 'page one' do
          it 'returns the product, newest and popular first' do
            params = { 'page' => 1, 'per_page' => 1 }
            product_json = product_api.call(:index, params)
            body_parsed = JSON.parse(product_json[2][0])
            expect(body_parsed[0]['id']).to eq other_product.id
            expect(body_parsed[0]['title']).to eq other_product.title
            expect(body_parsed[0]['msrp_price']).to eq other_product.msrp_price
            expect(body_parsed[0]['unfair_rate']).to eq other_product.unfair_rate
            expect(body_parsed[0]['people_needed']).to eq other_product.people_needed_hash.to_json
            expect(body_parsed[0]['description']).to eq other_product.description
            expect(body_parsed[0]['categories']).to match_array other_product.categories.map { |category| { id: category.id, name: category.name }.to_json }
            expect(body_parsed[0]['products_count']).to eq Product.count
          end
        end

        context 'page two' do
          it 'returns the product, newest and popular first' do
            params = { 'page' => 2, 'per_page' => 1 }
            product_json = product_api.call(:index, params)
            body_parsed = JSON.parse(product_json[2][0])
            expect(body_parsed[0]['id']).to eq product.id
            expect(body_parsed[0]['title']).to eq product.title
            expect(body_parsed[0]['msrp_price']).to eq product.msrp_price
            expect(body_parsed[0]['unfair_rate']).to eq product.unfair_rate
            expect(body_parsed[0]['people_needed']).to eq product.people_needed_hash.to_json
            expect(body_parsed[0]['description']).to eq product.description
            expect(body_parsed[0]['categories']).to match_array product.categories.map { |category| { id: category.id, name: category.name }.to_json }
            expect(body_parsed[0]['products_count']).to eq Product.count
          end
        end
      end
    end
    pending 'with no featured products'
  end

  describe '#liked' do
    let(:user) { Fabricate(:user) }
    let(:params) { { 'auth_token' => user.auth_token } }

    context 'unauthenticated' do
      it 'responds 404' do
        response = product_api.call(:liked)
        expect(response).to be_404
      end
    end

    context 'authenticated' do
      context 'when user has no products liked' do
        it 'returns an empty json' do
          response = product_api.call(:liked, params)
          expect(response).to be_200
          expect(response).to have_content '[]'
        end
      end

      context 'when user has products liked' do
        context 'and has just one' do
          it 'returns the product liked json' do
            product = Fabricate(:product_like, user: user).product
            Fabricate(:product_like) # it'll not appear

            response = product_api.call(:liked, params.merge('page' => 1, 'per_page' => 3))

            expect(response).to be_200
            body_parsed = JSON.parse(response[2][0])
            expect(body_parsed).to have(1).item
            expect(body_parsed[0]['id']).to eq product.id
            expect(body_parsed[0]['title']).to eq product.title
            expect(body_parsed[0]['msrp_price']).to eq product.msrp_price
            expect(body_parsed[0]['unfair_rate']).to eq product.unfair_rate
            expect(body_parsed[0]['people_needed']).to eq product.people_needed_hash.to_json
            expect(body_parsed[0]['description']).to eq product.description
            expect(body_parsed[0]['categories']).to match_array product.categories.map { |category| { id: category.id, name: category.name }.to_json }
          end
        end

        context 'and has more than one product liked' do
          context 'with three products, and the third as most popular and the first as popular' do
            let!(:first_product) { Fabricate(:product, higgles_count: 2) }
            let!(:second_product) { Fabricate(:product, higgles_count: 1) }
            let!(:third_product) { Fabricate(:product, higgles_count: 5) }
            let!(:out_product) { Fabricate(:product) }

            let!(:first_like) { Fabricate(:product_like, user: user, product: first_product) }
            let!(:second_like) { Fabricate(:product_like, user: user, product: second_product) }
            let!(:third_like) { Fabricate(:product_like, user: user, product: third_product) }
            let!(:out_like) { Fabricate(:product_like, user: user, product: out_product) }

            it 'returns the products liked json paginated' do
              response = product_api.call(:liked, params.merge('page' => 1, 'per_page' => 3))
              expect(response).to be_200

              body_parsed = JSON.parse(response[2][0])
              expect(body_parsed).to have(3).items
              expect(body_parsed[0]['id']).to eq third_product.id
              expect(body_parsed[0]['title']).to eq third_product.title
              expect(body_parsed[0]['msrp_price']).to eq third_product.msrp_price
              expect(body_parsed[0]['unfair_rate']).to eq third_product.unfair_rate
              expect(body_parsed[0]['people_needed']).to eq third_product.people_needed_hash.to_json
              expect(body_parsed[0]['description']).to eq third_product.description
              expect(body_parsed[0]['categories']).to match_array third_product.categories.map { |category| { id: category.id, name: category.name }.to_json }

              expect(body_parsed[1]['id']).to eq first_product.id
              expect(body_parsed[1]['title']).to eq first_product.title
              expect(body_parsed[1]['msrp_price']).to eq first_product.msrp_price
              expect(body_parsed[1]['unfair_rate']).to eq first_product.unfair_rate
              expect(body_parsed[1]['people_needed']).to eq first_product.people_needed_hash.to_json
              expect(body_parsed[1]['description']).to eq first_product.description
              expect(body_parsed[1]['categories']).to match_array first_product.categories.map { |category| { id: category.id, name: category.name }.to_json }

              expect(body_parsed[2]['id']).to eq second_product.id
              expect(body_parsed[2]['title']).to eq second_product.title
              expect(body_parsed[2]['msrp_price']).to eq second_product.msrp_price
              expect(body_parsed[2]['unfair_rate']).to eq second_product.unfair_rate
              expect(body_parsed[2]['people_needed']).to eq second_product.people_needed_hash.to_json
              expect(body_parsed[2]['description']).to eq second_product.description
              expect(body_parsed[2]['categories']).to match_array second_product.categories.map { |category| { id: category.id, name: category.name }.to_json }
            end
          end
        end
      end
    end
  end

  describe '#like' do
    context 'unauthenticated' do
      it 'responds 404' do
        response = product_api.call(:like)
        expect(response).to be_404
      end
    end

    context 'authenticated' do
      let(:user) { Fabricate(:user) }
      let(:params) { { 'auth_token' => user.auth_token } }
      context 'with no product passed as parameter' do
        it 'responds 404' do
          response = product_api.call(:like, params)
          expect(response).to be_404
        end
      end

      context 'with an invalid product passed as parameter' do
        it 'responds 404' do
          response = product_api.call(:like, params.merge(product_id: 'bla'))
          expect(response).to be_404
        end
      end

      context 'with valid product passed as parameter' do
        let(:product) { Fabricate :product }
        it 'like the product' do
          response = product_api.call(:like, params.merge(product_id: product.id))
          expect(response).to be_200
          expect(Product.last).to have_likes
          expect(Product.last.users_that_like.last).to eq user
        end
      end
    end
  end

  describe '#dislike' do
    context 'unauthenticated' do
      it 'responds 404' do
        response = product_api.call(:dislike)
        expect(response).to be_404
      end
    end

    context 'authenticated' do
      let(:user) { Fabricate(:user) }
      let(:params) { { 'auth_token' => user.auth_token } }
      context 'with no product passed as parameter' do
        it 'responds 404' do
          response = product_api.call(:dislike, params)
          expect(response).to be_404
        end
      end

      context 'with an invalid product passed as parameter' do
        it 'responds 404' do
          response = product_api.call(:dislike, params.merge(product_id: 'bla'))
          expect(response).to be_404
        end
      end

      context 'with valid product passed as parameter' do
        let(:product) { Fabricate :product }
        it 'like the product' do
          response = product_api.call(:dislike, params.merge(product_id: product.id))
          expect(response).to be_200
          expect(Product.last).not_to have_likes
        end
      end
    end
  end
end

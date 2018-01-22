describe 'User API' do
  let(:user_api) { UserAPI.new }
  describe '#show' do

    context 'with an inexistent user' do
      it 'responds 404' do
        params = { user_id: 232 }
        response = user_api.call(:show, params)
        expect(response).to be_404
      end
    end

    context 'with an existent user' do
      let(:address) { Fabricate :address }
      let(:category) { Fabricate :category }
      let(:other_category) { Fabricate :category }
      let(:higgle) { Fabricate :higgle }
      let!(:order) { Fabricate :order, user: user, higgle: higgle }
      let!(:user) { Fabricate :user, address: address, last4_credit_card: '5192', categories: [category, other_category] }
      let!(:product_like) { Fabricate :product_like, user: user }
      it 'responds with the user information' do

        expected_return = {
          full_name: user.full_name,
          auth_token: user.auth_token,
          last4_credit_card: user.last4_credit_card,
          credit_card_holder_name: user.credit_card_holder_name,
          credit_card_expiration_month: user.credit_card_expiration_month,
          credit_card_expiration_year: user.credit_card_expiration_year,
          about: user.about,
          follower_count: user.follower_count,
          followee_count: user.followee_count,
          email: user.email,
          address_line: user.address.address_line,
          address_city: user.address.city,
          address_state: user.address.state,
          address_zipcode: user.address.zip_code,
          avatar: user.avatar.medium.url,
          categories: user.categories.map { |category| { category_id: category.id } },
          groups: user.joined_groups.map { |group| { group_id: group.id } },
          likes: user.likes.map { |product_like| { product_id: product_like.product.id } },
          higgles: user.higgles.map { |higgle| { higgle_id: higgle.id } }
        }

        params = { user_id: user.id }

        response = user_api.call(:show, params)
        expect(response).to be_200
        expect(response[2]).to match_array [expected_return.to_json]
      end
    end
  end

  describe '#find_by_email' do

    context 'with an inexistent email' do
      it 'responds 404' do
        params = { email: 'bla@foo.com.br' }
        response = user_api.call(:find_by_email, params)
        expect(response).to be_404
      end
    end

    context 'with an existent email' do
      let(:address) { Fabricate :address }
      let(:category) { Fabricate :category }
      let(:other_category) { Fabricate :category }
      let!(:user) { Fabricate :user, address: address, last4_credit_card: '5192', categories: [category, other_category] }
      let!(:product_like) { Fabricate :product_like, user: user }
      it 'responds with the user information' do
        expected_return = {
          full_name: user.full_name,
          auth_token: user.auth_token,
          last4_credit_card: user.last4_credit_card,
          credit_card_holder_name: user.credit_card_holder_name,
          credit_card_expiration_month: user.credit_card_expiration_month,
          credit_card_expiration_year: user.credit_card_expiration_year,
          about: user.about,
          follower_count: user.follower_count,
          followee_count: user.followee_count,
          email: user.email,
          address_line: user.address.address_line,
          address_city: user.address.city,
          address_state: user.address.state,
          address_zipcode: user.address.zip_code,
          avatar: user.avatar.medium.url,
          categories: user.categories.map { |category| { category_id: category.id } },
          groups: user.joined_groups.map { |group| { group_id: group.id } },
          likes: user.likes.map { |product_like| { product_id: product_like.product.id } },
          higgles: user.higgles.map { |higgle| { higgle_id: higgle.id } }
        }

        params = { email: user.email }

        response = user_api.call(:find_by_email, params)
        expect(response).to be_200
        expect(response[2]).to match_array [expected_return.to_json]
      end
    end
  end
end

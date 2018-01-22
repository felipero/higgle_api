describe 'Higgle API' do
  let(:higgle_api) { HiggleAPI.new }
  let(:category) { Fabricate :category }
  let!(:product_on_category) { Fabricate :product, categories: [category] }
  let(:address) { Fabricate :address }
  let!(:user) { Fabricate :user, address: address }

  describe '#create' do
    context 'with valid params' do
      let(:valid_params) do
        {
          'product_id' => product_on_category.id,
          'higgle_price' => 100,
          'quantity' => 1,
          'address_line' => 'Xpto Bla Avenue, 105',
          'address_city' => 'Sbrubbles',
          'address_state' => 'RT',
          'address_zipcode' => '747663',
          'last4_credit_card' => '4242424242424242'
        }
      end

      context 'and no group' do
        context 'and same address sent' do
          let(:valid_params) do
            {
              'product_id' => product_on_category.id,
              'higgle_price' => 100,
              'quantity' => 1,
              'address_line' => address.address_line,
              'address_city' => address.city,
              'address_state' => address.state,
              'address_zipcode' => address.zip_code,
              'last4_credit_card' => '4242424242424242'
            }
          end

          it 'creates the higgle' do
            higgle_api.call(:create, valid_params.merge({ 'auth_token' => user.auth_token }))
            expect(Higgle.last.product).to eq product_on_category
            expect(Higgle.last.merchant).to eq product_on_category.merchant
            expect(Higgle.last.creator).to eq user
            expect(Higgle.last.categories).to match_array product_on_category.categories
            expect(Higgle.last.higgle_price).to eq 100
            expect(Higgle.last.quantity_sold).to eq 1
            expect(Higgle.last.buy_it_now).to be_falsey
            expect(Higgle.last.status).to eq 'running'

            expect(Order.last.amount).to eq 100
            expect(Order.last.address.address_line).to eq address.address_line
            expect(Order.last.address.city).to eq address.city
            expect(Order.last.address.state).to eq address.state
            expect(Order.last.address.zip_code).to eq address.zip_code
          end
        end

        context 'and different address sent' do
          it 'creates the higgle' do
            higgle_api.call(:create, valid_params.merge({ 'auth_token' => user.auth_token }))

            expect(Order.last.amount).to eq 100
            expect(Order.last.address.address_line).to eq 'Xpto Bla Avenue, 105'
            expect(Order.last.address.city).to eq 'Sbrubbles'
            expect(Order.last.address.state).to eq 'RT'
            expect(Order.last.address.zip_code).to eq '747663'
          end
        end

        context 'and sending an address to a no addressable user' do
          let!(:user) { Fabricate :user, address: nil }
          it 'includes the address' do
            higgle_api.call(:create, valid_params.merge({ 'auth_token' => user.auth_token }))

            expect(User.last.address.address_line).to eq 'Xpto Bla Avenue, 105'
            expect(User.last.address.city).to eq 'Sbrubbles'
            expect(User.last.address.state).to eq 'RT'
            expect(User.last.address.zip_code).to eq '747663'
            expect(User.last.address.addressable_type).to eq 'User'

            expect(Order.last.address.address_line).to eq 'Xpto Bla Avenue, 105'
            expect(Order.last.address.city).to eq 'Sbrubbles'
            expect(Order.last.address.state).to eq 'RT'
            expect(Order.last.address.zip_code).to eq '747663'
            expect(Order.last.address.addressable_type).to eq 'Order'
          end
        end

        context 'and same billing card sent' do
          let(:valid_params) do
            {
              'product_id' => product_on_category.id,
              'higgle_price' => 100,
              'quantity' => 1,
              'last4_credit_card' => "545363724455#{user.last4_credit_card}",
              'credit_card_holder_name' => user.credit_card_holder_name,
              'credit_card_expiration_month' => user.credit_card_expiration_month,
              'credit_card_expiration_year' => user.credit_card_expiration_year,
              'cvc' => '000'
            }
          end
          it 'keep the current billing information considering only the last four digits informed' do
            expect_any_instance_of(User).to receive(:update_card).never
            higgle_api.call(:create, valid_params.merge({ 'auth_token' => user.auth_token }))
          end
        end

        context 'and different billing cards' do
          let(:valid_params) do
            {
              'product_id' => product_on_category.id,
              'higgle_price' => 100,
              'quantity' => 1,
              'last4_credit_card' => '5352',
              'credit_card_holder_name' => 'bla-xpto',
              'credit_card_expiration_month' => 12,
              'credit_card_expiration_year' => 2045,
              'cvc' => '000'
            }
          end
          it 'update the billing information' do
            expect_any_instance_of(User).to receive(:update_card).once
            higgle_api.call(:create, valid_params.merge({ 'auth_token' => user.auth_token }))
          end
        end
      end

      context 'and with group' do
        let(:group) { Fabricate :group, leader: user }
        let(:valid_params) { { 'product_id' => product_on_category.id, 'group_id' => group.id, 'higgle_price' =>  100, 'quantity' => 1, 'last4_credit_card' => '4242424242424242' } }
        it 'creates the higgle' do
          response = higgle_api.call(:create, valid_params.merge({ 'auth_token' => user.auth_token }))
          expect(Higgle.last.product).to eq product_on_category
          expect(Higgle.last.merchant).to eq product_on_category.merchant
          expect(Higgle.last.group).to eq group
          expect(Higgle.last.creator).to eq user
          expect(Higgle.last.categories).to match_array product_on_category.categories
          expect(Higgle.last.higgle_price).to eq 100
          expect(Higgle.last.buy_it_now).to be_falsey
          expect(Higgle.last.status).to eq 'running'
          expected_return = { slug: Higgle.last.slug }
          expect(response[2]).to eq [expected_return.to_json]
        end
      end
    end

    context 'with invalid params' do
      context 'when no product informed' do
        let(:invalid_params) { { 'higgle_price' => 100, 'quantity' => 1 } }
        it 'responds with 404' do
          response = higgle_api.call(:create, invalid_params.merge({ 'auth_token' => user.auth_token }))
          expect(response[0]).to eq 404
        end
      end

      context 'when no price informed' do
        let(:invalid_params) { { 'product_id' => product_on_category.id } }

        it 'responds with 501' do
          response = higgle_api.call(:create, invalid_params.merge({ 'auth_token' => user.auth_token }))
          expect(response[0]).to eq 501
          expect(response[2]).to eq [{ 'message': I18n.t('api.commom.internal_server_error') }.to_json]
        end
      end

      context 'when no quantity informed' do
        let(:invalid_params) { { 'product_id' => product_on_category.id, 'higgle_price' => 100 } }

        it 'responds with 501' do
          response = higgle_api.call(:create, invalid_params.merge({ 'auth_token' => user.auth_token }))
          expect(response[0]).to eq 501
          expect(response[2]).to eq [{ 'message': I18n.t('api.commom.internal_server_error') }.to_json]
        end
      end

      context 'when credit card invalid' do
        context 'and credit card is not registered' do
          it 'responds with forbidden' do
            user = Fabricate(:user, address: address)
            user[:has_credit_card] = false
            user.save
            higgle = Fabricate(:running_higgle)
            invalid_params = { 'higgle_id' => higgle.id,
                               'quantity' => 2,
                               'auth_token' => user.auth_token }
            response = higgle_api.call(:join, invalid_params)
            expect(response).to be_403
            expect(response).to be_a_json_eq [{ errors: { user: ["a valid credit card required"] } }.to_json]
          end
        end
      end

      context 'and some credit card info is invalid' do
        it 'responds with forbidden' do
          invalid_params = { 'product_id' => product_on_category.id,
                             'higgle_price' => 100,
                             'quantity' => 2,
                             'last4_credit_card' => '4242424242424242',
                             'auth_token' => user.auth_token }
          expect(OrderTransaction).to receive(:charge!).and_raise(Stripe::CardError.new(nil, nil, nil))
          response = higgle_api.call(:create, invalid_params)
          expect(response).to be_403
          expect(response).to be_a_json_eq [{ 'message': I18n.t('api.commom.internal_server_error') }.to_json]
        end
      end
    end
  end

  describe '#login' do
    context 'with a valid login' do
      let(:category) { Fabricate :category }
      let(:other_category) { Fabricate :category }
      let!(:user) { Fabricate :user, address: address, last4_credit_card: '5192', categories: [category, other_category] }
      let!(:product_like) { Fabricate :product_like, user: user }
      let(:valid_params) { { 'auth_token' => user.auth_token } }

      it 'responds with 200 and the token' do
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

        response = higgle_api.call(:login, valid_params)
        expect(response[0]).to eq 200
        expect(response[2]).to match_array [expected_return.to_json]
      end
    end

    pending 'with joined groups'

    context 'with an invalid login' do
      let(:valid_params) { { 'auth_token' => 'bla' } }
      it 'responds not_found' do
        response = higgle_api.call(:login, valid_params)
        expect(response[0]).to eq 404
      end
    end
  end

  describe '#index' do
    let(:product) { Fabricate(:product) }
    let(:other_product) { Fabricate(:product) }

    context 'with a running higgle' do
      let!(:higgle) { Fabricate :higgle, product: product }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds 200 with an array with the running higgle' do
        expected_return = [{
                             id: higgle.id,
                             higgle_price: higgle.higgle_price,
                             orders_count: higgle.orders_count,
                             title: higgle.title,
                             short_description: higgle.short_description,
                             status: higgle.status,
                             quantity_sold: higgle.quantity_sold,
                             msrp: product.msrp_price,
                             image: product.picture.big.url,
                             product_id: higgle.product.id,
                             end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                             creator_id: higgle.creator.id,
                             creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                             creator_avatar: higgle.creator.avatar.url,
                             comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                             share_path: "/higgles/#{higgle.slug}"
                           }]

        response = higgle_api.call(:index)
        expect(response[0]).to eq 200
        expect(response[2]).to eq [expected_return.to_json]
      end
    end

    context 'with two running higgles' do
      let!(:higgle) { Fabricate(:running_higgle, product: product, updated_at: 5.seconds.ago) }
      let!(:other_higgle) { Fabricate(:running_higgle, product: other_product, updated_at: 1.second.ago) }
      it 'responds 200 with an array with the running higgle' do
        expected_return =
          [
            {
              id: other_higgle.id,
              higgle_price: other_higgle.higgle_price,
              orders_count: other_higgle.orders_count,
              title: other_higgle.title,
              short_description: other_higgle.short_description,
              status: other_higgle.status,
              quantity_sold: other_higgle.quantity_sold,
              msrp: other_higgle.product.msrp_price,
              image: other_higgle.product.picture.big.url,
              product_id: other_product.id,
              end_date: other_higgle.end_date.strftime('%d%m%Y%H%M'),
              creator_id: other_higgle.creator.id,
              creator_name: "#{other_higgle.creator.last_name}, #{higgle.creator.first_name}",
              creator_avatar: other_higgle.creator.avatar.url,
              comments: other_higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
              share_path: "/higgles/#{other_higgle.slug}"
            },
            {
              id: higgle.id,
              higgle_price: higgle.higgle_price,
              orders_count: higgle.orders_count,
              title: higgle.title,
              short_description: higgle.short_description,
              status: higgle.status,
              quantity_sold: higgle.quantity_sold,
              msrp: higgle.product.msrp_price,
              image: higgle.product.picture.big.url,
              product_id: higgle.product.id,
              end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
              creator_id: higgle.creator.id,
              creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
              creator_avatar: higgle.creator.avatar.url,
              comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
              share_path: "/higgles/#{higgle.slug}"
            }
          ]

        response = higgle_api.call(:index)
        expect(response[0]).to eq 200
        expect(response[2]).to match_array [expected_return.to_json]
      end
    end

    context 'with no running higgle' do
      let!(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_PENDING }
      it 'responds 200 with an empty array' do
        response = higgle_api.call(:index)
        expect(response[0]).to eq 200
        expect(response[2]).to eq ['[]']
      end
    end

    context 'with an order' do
      let(:higgle) { Fabricate :higgle, product: product }
      let!(:order) { Fabricate :order, higgle: higgle }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds 200 with an array with the running higgle and the order count as one' do
        expected_return = [{
                             id: higgle.id,
                             higgle_price: higgle.higgle_price,
                             orders_count: 1,
                             title: higgle.title,
                             short_description: higgle.short_description,
                             status: higgle.status,
                             quantity_sold: higgle.quantity_sold,
                             msrp: product.msrp_price,
                             image: product.picture.big.url,
                             product_id: higgle.product.id,
                             end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                             creator_id: higgle.creator.id,
                             creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                             creator_avatar: higgle.creator.avatar.url,
                             comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                             share_path: "/higgles/#{higgle.slug}"
                           }]

        response = higgle_api.call(:index)
        expect(response[0]).to eq 200
        expect(response[2]).to eq [expected_return.to_json]
      end
    end
  end

  describe '#join' do
    let(:product) { Fabricate :product }

    context 'with a running higgle' do
      let(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_RUNNING }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds 200 with a message confirming the order' do
        params = { higgle_id: higgle.id, 'quantity' => 1, 'last4_credit_card' => '4242424242424242', 'auth_token' => user.auth_token }
        response = higgle_api.call(:join, params)
        expect(response[0]).to eq 200
        order = Order.last
        expect(order.user).to eq user
        expect(order.amount).to eq higgle.higgle_price
      end
    end

    context 'when credit card invalid' do
      context 'and credit card is not registered' do
        it 'responds with forbidden' do
          user = Fabricate(:user, address: address)
          user[:has_credit_card] = false
          user.save
          higgle = Fabricate(:running_higgle)
          invalid_params = { 'higgle_id' => higgle.id,
                             'quantity' => 2,
                             'auth_token' => user.auth_token }
          response = higgle_api.call(:join, invalid_params)
          expect(response).to be_403
          expect(response).to be_a_json_eq [{ errors: { user: ["a valid credit card required"] } }.to_json]
        end
      end

      context 'and some credit card info is invalid' do
        it 'responds with forbidden' do
          higgle = Fabricate(:running_higgle)
          invalid_params = { 'higgle_id' => higgle.id,
                             'quantity' => 2,
                             'auth_token' => user.auth_token }
          expect(OrderTransaction).to receive(:charge!).and_raise(Stripe::CardError.new(nil, nil, nil))
          response = higgle_api.call(:join, invalid_params)
          expect(response).to be_403
          expect(response).to be_a_json_eq [{ 'message': I18n.t('api.commom.internal_server_error') }.to_json]
        end
      end
    end

    context 'with an invalid higgle' do
      let(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_WON }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds not_found' do
        params = { higgle_id: higgle.id, 'quantity' => 1, 'auth_token' => user.auth_token }
        response = higgle_api.call(:join, params)
        expect(response[0]).to eq 404
      end
    end

    context 'with an invalid user' do
      let(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_RUNNING }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds not_found' do
        params = { higgle_id: higgle.id, 'quantity' => 1, 'auth_token' => 'bla' }
        response = higgle_api.call(:join, params)
        expect(response[0]).to eq 404
      end
    end
  end

  describe '#higgles_created_by_user' do
    context 'with a valid user' do
      let(:product) { Fabricate :product }
      let(:other_product) { Fabricate :product }

      context 'having no higgles' do
        it 'responds 200 with an array with the running higgle' do
          params = { 'auth_token' => user.auth_token }
          response = higgle_api.call(:higgles_created_by_user, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq ['[]']
        end
      end

      context 'having one higgle' do
        let!(:higgle) { Fabricate :higgle, product: product, creator: user }
        before { Fabricate.times(2, :comment, higgle: higgle) }
        it 'responds 200 with an array with the running higgle' do
          expected_return = [{
                               id: higgle.id,
                               higgle_price: higgle.higgle_price,
                               orders_count: higgle.orders_count,
                               title: higgle.title,
                               short_description: higgle.short_description,
                               status: higgle.status,
                               quantity_sold: higgle.quantity_sold,
                               msrp: product.msrp_price,
                               image: product.picture.big.url,
                               product_id: higgle.product.id,
                               end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                               creator_id: higgle.creator.id,
                               creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                               creator_avatar: higgle.creator.avatar.url,
                               comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                               share_path: "/higgles/#{higgle.slug}"
                             }]
          params = { 'auth_token' => user.auth_token }
          response = higgle_api.call(:higgles_created_by_user, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'having two higgles' do
        let!(:higgle) { Fabricate :higgle, product: product, creator: user, end_date: 1.day.ago }
        let!(:other_higgle) { Fabricate :higgle, product: other_product, creator: user, end_date: 1.day.from_now }
        before { Fabricate.times(2, :comment, higgle: higgle) }
        it 'responds 200 with an array with the running higgle' do
          expected_return =
            [
              {
                id: other_higgle.id,
                higgle_price: other_higgle.higgle_price,
                orders_count: other_higgle.orders_count,
                title: other_higgle.title,
                short_description: other_higgle.short_description,
                status: other_higgle.status,
                quantity_sold: higgle.quantity_sold,
                msrp: other_product.msrp_price,
                image: other_product.picture.big.url,
                product_id: other_product.id,
                end_date: other_higgle.end_date.strftime('%d%m%Y%H%M'),
                creator_id: other_higgle.creator.id,
                creator_name: "#{other_higgle.creator.last_name}, #{other_higgle.creator.first_name}",
                creator_avatar: other_higgle.creator.avatar.url,
                comments: other_higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                share_path: "/higgles/#{other_higgle.slug}"
              },
              {
                id: higgle.id,
                higgle_price: higgle.higgle_price,
                orders_count: higgle.orders_count,
                title: higgle.title,
                short_description: higgle.short_description,
                status: higgle.status,
                quantity_sold: higgle.quantity_sold,
                msrp: product.msrp_price,
                image: product.picture.big.url,
                product_id: product.id,
                end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                creator_id: higgle.creator.id,
                creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                creator_avatar: higgle.creator.avatar.url,
                comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                share_path: "/higgles/#{higgle.slug}"
              }
            ]
          params = { 'auth_token' => user.auth_token }
          response = higgle_api.call(:higgles_created_by_user, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end
    end

    context 'with an invalid user' do
      it 'responds 404' do
        params = { 'auth_token' => 'bla' }
        response = higgle_api.call(:higgles_created_by_user, params)
        expect(response[0]).to eq 404
      end
    end

    context 'with no token provided' do
      it 'responds 404' do
        response = higgle_api.call(:higgles_created_by_user, {})
        expect(response[0]).to eq 404
      end
    end
  end

  describe '#for_category' do
    let(:category) { Fabricate :category }
    let(:product) { Fabricate :product, categories: [category] }
    let(:other_product) { Fabricate :product, categories: [category] }

    context 'having no higgles' do
      it 'responds 200 with an array with the running higgle' do
        params = { 'category_id' => category.id }
        response = higgle_api.call(:for_category, params)
        expect(response[0]).to eq 200
        expect(response[2]).to eq ['[]']
      end
    end

    context 'having one higgle' do
      let!(:higgle) { Fabricate :higgle, product: product }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds 200 with an array with the running higgle' do
        expected_return = [{
                             id: higgle.id,
                             higgle_price: higgle.higgle_price,
                             orders_count: higgle.orders_count,
                             title: higgle.title,
                             short_description: higgle.short_description,
                             status: higgle.status,
                             quantity_sold: higgle.quantity_sold,
                             msrp: product.msrp_price,
                             image: product.picture.big.url,
                             product_id: higgle.product.id,
                             end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                             creator_id: higgle.creator.id,
                             creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                             creator_avatar: higgle.creator.avatar.url,
                             comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                             share_path: "/higgles/#{higgle.slug}"
                           }]
        params = { 'category_id' => category.id }
        response = higgle_api.call(:for_category, params)
        expect(response[0]).to eq 200
        expect(response[2]).to eq [expected_return.to_json]
      end
    end

    context 'having two higgles' do
      context 'for different products' do
        let!(:higgle) { Fabricate :higgle, product: product, end_date: 1.day.ago }
        before { Fabricate.times(2, :comment, higgle: higgle) }
        let!(:other_higgle) { Fabricate :higgle, product: other_product, creator: user, end_date: 1.day.from_now }
        it 'responds 200 with an array with the running higgle' do
          expected_return =
            [
              {
                id: other_higgle.id,
                higgle_price: other_higgle.higgle_price,
                orders_count: other_higgle.orders_count,
                title: other_higgle.title,
                short_description: other_higgle.short_description,
                status: other_higgle.status,
                quantity_sold: higgle.quantity_sold,
                msrp: other_product.msrp_price,
                image: other_product.picture.big.url,
                product_id: other_product.id,
                end_date: other_higgle.end_date.strftime('%d%m%Y%H%M'),
                creator_id: other_higgle.creator.id,
                creator_name: "#{other_higgle.creator.last_name}, #{other_higgle.creator.first_name}",
                creator_avatar: other_higgle.creator.avatar.url,
                comments: other_higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                share_path: "/higgles/#{other_higgle.slug}"
              },
              {
                id: higgle.id,
                higgle_price: higgle.higgle_price,
                orders_count: higgle.orders_count,
                title: higgle.title,
                short_description: higgle.short_description,
                status: higgle.status,
                quantity_sold: higgle.quantity_sold,
                msrp: product.msrp_price,
                image: product.picture.big.url,
                product_id: product.id,
                end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                creator_id: higgle.creator.id,
                creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                creator_avatar: higgle.creator.avatar.url,
                comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                share_path: "/higgles/#{higgle.slug}"
              }
            ]
          params = { 'category_id' => category.id }
          response = higgle_api.call(:for_category, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end

      end

      context 'for same products' do
        let!(:higgle) { Fabricate :higgle, product: product, end_date: 1.day.from_now }
        before { Fabricate.times(2, :comment, higgle: higgle) }
        let!(:other_higgle) { Fabricate :higgle, product: product, creator: user, end_date: 1.day.ago }
        it 'responds 200 with an array with the running higgle' do
          expected_return =
            [
              {
                id: higgle.id,
                higgle_price: higgle.higgle_price,
                orders_count: higgle.orders_count,
                title: higgle.title,
                short_description: higgle.short_description,
                status: higgle.status,
                quantity_sold: higgle.quantity_sold,
                msrp: product.msrp_price,
                image: product.picture.big.url,
                product_id: product.id,
                end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                creator_id: higgle.creator.id,
                creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                creator_avatar: higgle.creator.avatar.url,
                comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                share_path: "/higgles/#{higgle.slug}"
              }
            ]
          params = { 'category_id' => category.id }
          response = higgle_api.call(:for_category, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'paginated' do
        it 'paginates higgles returned' do
          Fabricate.times(3, :higgle, categories: [category])
          params = { 'category_id' => category.id }

          response = higgle_api.call(:for_category, params.merge('page' => 1, 'per_page' => 1))
          expect(response).to have_json_array_size(1)

          response = higgle_api.call(:for_category, params.merge('page' => 2, 'per_page' => 2))
          expect(response).to have_json_array_size(1)

          response = higgle_api.call(:for_category, params.merge('page' => 1, 'per_page' => 2))
          expect(response).to have_json_array_size(2)
        end
      end
    end
  end

  describe '#for_group' do
    let(:group) { Fabricate :group }
    let(:product) { Fabricate :product, categories: [category] }
    let(:other_product) { Fabricate :product, categories: [category] }

    context 'having no higgles' do
      it 'responds 200 with an array with the running higgle' do
        params = { 'group_id' => group.id }
        response = higgle_api.call(:for_group, params)
        expect(response[0]).to eq 200
        expect(response[2]).to eq ['[]']
      end
    end

    context 'having one higgle' do
      let!(:higgle) { Fabricate :higgle, group: group }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds 200 with an array with the running higgle' do
        expected_return = [{
                             id: higgle.id,
                             higgle_price: higgle.higgle_price,
                             orders_count: higgle.orders_count,
                             title: higgle.title,
                             short_description: higgle.short_description,
                             status: higgle.status,
                             quantity_sold: higgle.quantity_sold,
                             msrp: product.msrp_price,
                             image: product.picture.big.url,
                             product_id: higgle.product.id,
                             end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
                             creator_id: higgle.creator.id,
                             creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
                             creator_avatar: higgle.creator.avatar.url,
                             comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
                             share_path: "/higgles/#{higgle.slug}"
                           }]
        params = { 'group_id' => group.id }
        response = higgle_api.call(:for_group, params)
        expect(response[0]).to eq 200
        expect(response[2]).to eq [expected_return.to_json]
      end
    end

    context 'having two higgles' do
      let!(:higgle) { Fabricate :higgle, product: product, end_date: 1.day.ago, group: group }
      before { Fabricate.times(2, :comment, higgle: higgle) }
      it 'responds 200 with an array with the running higgle' do
        expected_return =
          [
            {
              id: other_higgle.id,
              higgle_price: other_higgle.higgle_price,
              orders_count: other_higgle.orders_count,
              title: other_higgle.title,
              short_description: other_higgle.short_description,
              status: other_higgle.status,
              quantity_sold: higgle.quantity_sold,
              msrp: other_product.msrp_price,
              image: other_product.picture.big.url,
              product_id: other_product.id,
              end_date: other_higgle.end_date.strftime('%d%m%Y%H%M'),
              creator_id: other_higgle.creator.id,
              creator_name: "#{other_higgle.creator.last_name}, #{other_higgle.creator.first_name}",
              creator_avatar: other_higgle.creator.avatar.url,
              comments: other_higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
              share_path: "/higgles/#{other_higgle.slug}"
            },
            {
              id: higgle.id,
              higgle_price: higgle.higgle_price,
              orders_count: higgle.orders_count,
              title: higgle.title,
              short_description: higgle.short_description,
              status: higgle.status,
              quantity_sold: higgle.quantity_sold,
              msrp: product.msrp_price,
              image: product.picture.big.url,
              product_id: product.id,
              end_date: higgle.end_date.strftime('%d%m%Y%H%M'),
              creator_id: higgle.creator.id,
              creator_name: "#{higgle.creator.last_name}, #{higgle.creator.first_name}",
              creator_avatar: higgle.creator.avatar.url,
              comments: higgle.comments.map { |comment| { id: comment.id, message: comment.message }.to_json },
              share_path: "/higgles/#{higgle.slug}"
            }
          ]
        params = { 'category_id' => category.id }
        response = higgle_api.call(:for_category, params)
        expect(response[0]).to eq 200
        expect(response[2]).to eq [expected_return.to_json]
      end
      let!(:other_higgle) { Fabricate :higgle, product: other_product, creator: user, end_date: 1.day.from_now, group: group }
    end
  end
end

describe 'Counter Offer API' do
  let(:counter_offer_api) { CounterOfferAPI.new }
  let!(:user) { Fabricate :user }

  describe '#index' do
    let(:product) { Fabricate :product }
    let(:other_product) { Fabricate :product }


    context 'with one counter offer to a running higgle' do

      context 'and no params provided' do
        let!(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_RUNNING }
        let!(:counter_offer) { Fabricate :counter_offer, higgle: higgle }

        it 'responds 200 with an array with the running higgle' do
          response = counter_offer_api.call(:show)
          expect(response[0]).to eq 404
        end
      end

      context 'and invalid higgle in params' do
        let!(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_RUNNING }
        let!(:counter_offer) { Fabricate :counter_offer, higgle: higgle }

        it 'responds 200 with an array with the running higgle' do
          params = { 'higgle_id' => 'bla', 'auth_token' => user.auth_token }
          response = counter_offer_api.call(:show, params)
          expect(response[0]).to eq 404
        end
      end

      context 'and no valid token provided' do
        let!(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_RUNNING }
        let!(:counter_offer) { Fabricate :counter_offer, higgle: higgle }

        it 'responds 200 with an array with the running higgle' do
          params = { 'higgle_id' => higgle.id }
          response = counter_offer_api.call(:show, params)
          expect(response[0]).to eq 404
        end
      end

      context 'and no order to current user' do
        let!(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_RUNNING }
        let!(:counter_offer) { Fabricate :counter_offer, higgle: higgle }

        it 'responds 200 with an array with the running higgle' do
          expected_return = {
            id: counter_offer.id,
            price: counter_offer.price,
            status: counter_offer.status,
            end_date: counter_offer.end_date.strftime('%d%m%Y%H%M'),
            quantity: nil,
            accepted: counter_offer.accepted_by?(user),
            declined: counter_offer.declined_by?(user)
          }
          params = { 'higgle_id' => higgle.id, 'auth_token' => user.auth_token }

          response = counter_offer_api.call(:show, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'and one order for current user' do
        let!(:higgle) { Fabricate :higgle, product: product, status: Higgle::STATUS_RUNNING }
        let!(:order) { Fabricate :order, quantity: 1, higgle: higgle, user: user }
        let!(:counter_offer) { Fabricate :counter_offer, higgle: higgle }

        it 'responds 200 with an array with the running higgle' do
          expected_return = {
            id: counter_offer.id,
            price: counter_offer.price,
            status: counter_offer.status,
            end_date: counter_offer.end_date.strftime('%d%m%Y%H%M'),
            quantity: higgle.order_for(user).quantity,
            accepted: counter_offer.accepted_by?(user),
            declined: counter_offer.declined_by?(user)
          }
          params = { 'higgle_id' => higgle.id, 'auth_token' => user.auth_token }

          response = counter_offer_api.call(:show, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end
    end

    context 'with no higgle id informed' do
      let(:higgle) { Fabricate :higgle, product: product }
      let!(:counter_offer) { Fabricate :counter_offer, higgle: higgle }
      it 'responds 404' do
        response = counter_offer_api.call(:show)
        expect(response[0]).to eq 404
      end
    end
  end

  describe '#accept' do
    let(:counter_offer) { Fabricate :counter_offer }
    let!(:order) { Fabricate :order, user: user }

    context 'with valid token, correct counter offer and order' do
      it 'accepts the counter offer' do
        params = { 'counter_offer_id' => counter_offer.id, 'auth_token' => user.auth_token }
        expect(OrderTransaction).to receive(:accept_counter_offer!).once
        response = counter_offer_api.call(:accept, params)
        expect(response[0]).to eq 200
      end
    end

    context 'without token' do
      it 'responds 404' do
        params = { 'counter_offer_id' => counter_offer.id, 'order_id' => order.id }
        response = counter_offer_api.call(:accept, params)
        expect(response[0]).to eq 404
      end
    end

    context 'without counter offer' do
      it 'responds 404' do
        params = { 'order_id' => order.id, 'auth_token' => user.auth_token }
        response = counter_offer_api.call(:accept, params)
        expect(response[0]).to eq 404
      end
    end
  end

  describe '#decline' do
    let(:counter_offer) { Fabricate :counter_offer }

    context 'with valid token, correct counter offer and order' do
      it 'accepts the counter offer' do
        params = { 'counter_offer_id' => counter_offer.id, 'auth_token' => user.auth_token }
        expect_any_instance_of(CounterOffer).to receive(:decline!).with(user)
        response = counter_offer_api.call(:decline, params)
        expect(response[0]).to eq 200
      end
    end

    context 'without token' do
      it 'responds 404' do
        params = { 'counter_offer_id' => counter_offer.id }
        response = counter_offer_api.call(:decline, params)
        expect(response[0]).to eq 404
      end
    end

    context 'without counter offer' do
      it 'responds 404' do
        params = { 'auth_token' => user.auth_token }
        response = counter_offer_api.call(:decline, params)
        expect(response[0]).to eq 404
      end
    end
  end
end

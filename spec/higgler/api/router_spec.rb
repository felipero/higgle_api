describe Higgler::API::Route do

  context 'with correct controller and action passed' do
    context 'for product index' do
      it 'returns 200' do
        router = Higgler::API::Route.new(ProductAPI, 'index', ' xpto', ['bla'], 'GET')
        expect(router.call).to eq [200, { 'Content-Type' => 'application/json' }, ['[]']]
      end
    end

    context 'for higgle create' do
      it 'returns 200 with message "Checkout posted."' do
        address = Fabricate :address
        user = Fabricate :user, address: address
        higgle = Fabricate :higgle
        allow(User).to receive(:find_by).with(anything).and_return(user)
        router = Higgler::API::Route.new(HiggleAPI, 'create', 'xpto', ['bla'], 'POST')
        expect_any_instance_of(HiggleAPI).to receive(:create_higgle).and_return(higgle)
        allow_any_instance_of(HiggleAPI).to receive(:create_order)
        expect(router.call({ 'quantity' => 1, 'higgle_price' => 100, 'last4_credit_card' => '4242424242424242' })).to eq [200, { 'Content-Type' => 'application/json' }, [{ slug: higgle.slug }.to_json]]
      end
    end
  end
end

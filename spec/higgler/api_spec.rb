describe Higgler::API do
  let(:api) { Higgler::API.instance }

  describe '#call' do
    context 'with an invalid route path' do
      it 'responds 404' do
        env = {}
        env['PATH_INFO'] = 'bla/xpto/foo'
        env['REQUEST_METHOD'] = 'GET'
        expect(api.call(env)).to eq [404, { 'Content-Type' => 'application/json' }, ['Route not found']]
      end
    end

    context 'with a valid route and an invalid method' do
      it 'responds 404' do
        env = {}
        env['rack.input'] = StringIO.new
        env['PATH_INFO'] = '/products/'
        env['REQUEST_METHOD'] = 'FOO'
        expect(api.call(env)).to eq [404, { 'Content-Type' => 'application/json' }, ['Route not found']]
      end
    end

    context 'with a valid route path' do
      it 'responds 200' do
        env = {}
        env['rack.input'] = StringIO.new
        env['PATH_INFO'] = '/products/'
        env['REQUEST_METHOD'] = 'GET'
        expect(api.call(env)).to eq [200, { 'Content-Type' => 'application/json' }, ['[]']]
      end
    end

    context 'with a valid user and pass' do
      it 'responds 200' do
        env = {}
        env['rack.input'] = StringIO.new
        env['PATH_INFO'] = '/products/'
        env['REQUEST_METHOD'] = 'GET'
        user = Fabricate :user
        env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user.email, user.password)
        expect(api.call(env)).to eq [200, { 'Content-Type' => 'application/json' }, ['[]']]
      end
    end
  end
end

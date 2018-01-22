describe 'Group API', type: :api do
  let(:group_api) { GroupAPI.new }

  describe '#index' do
    context 'when having no groups' do
      context 'with no products' do
        it 'return an empty array' do
          params = { page: nil, per_page: nil }
          response = group_api.call(:index, params)
          expect(response[0]).to eq 200
          expect(response[2]).to eq ['[]']
        end
      end
    end

    context 'when having groups' do
      context 'one group' do
        context 'with no products' do
          let!(:group) { Fabricate :group }

          it 'return all groups' do
            params = { page: nil, per_page: nil }
            response = group_api.call(:index, params)
            expect(response[0]).to eq 200
            expect(response[2]).to eq ['[]']
          end
        end

        context 'with one product' do
          let!(:category) { Fabricate :category }
          let!(:product) { Fabricate :product, categories: [category] }
          context 'active' do
            let!(:group) { Fabricate :group, categories: [category], active: true }

            it 'return all groups with the product' do
              params = { page: nil, per_page: nil }
              response = group_api.call(:index, params)
              expected_return =
                [
                  {
                    id: group.id,
                    name: group.name,
                    members_count: group.members.count,
                    higgles_count: group.higgles.count,
                    group_type: group.group_type,
                    products: group.products.map { |product| { id: product.id, product_image: product.picture.big.url } },
                    leader_name: group.leader_name
                  }
                ]
              expect(response[0]).to eq 200
              expect(response[2]).to eq [expected_return.to_json]
            end
          end

          context 'inactive' do
            let!(:group) { Fabricate :group, categories: [category], active: false }

            it 'return all groups with the product' do
              params = { page: nil, per_page: nil }
              response = group_api.call(:index, params)
              expect(response[0]).to eq 200
              expect(response[2]).to eq ['[]']
            end
          end

          context 'public' do
            let!(:group) { Fabricate :group, categories: [category], group_type: Group::PUBLIC }

            it 'return all groups with the product' do
              params = { page: nil, per_page: nil }
              response = group_api.call(:index, params)
              expected_return =
                [
                  {
                    id: group.id,
                    name: group.name,
                    members_count: group.members.count,
                    higgles_count: group.higgles.count,
                    group_type: group.group_type,
                    products: group.products.map { |product| { id: product.id, product_image: product.picture.big.url } },
                    leader_name: group.leader_name
                  }
                ]
              expect(response[0]).to eq 200
              expect(response[2]).to eq [expected_return.to_json]
            end
          end

          context 'private' do
            let!(:group) { Fabricate :group, categories: [category], group_type: Group::PRIVATE }

            it 'return all groups with the product' do
              params = { page: nil, per_page: nil }
              response = group_api.call(:index, params)
              expect(response[0]).to eq 200
              expect(response[2]).to eq ['[]']
            end
          end
        end

        context 'with two products' do
          let!(:category) { Fabricate :category }
          let!(:product) { Fabricate :product, categories: [category] }
          let!(:group) { Fabricate :group, categories: [category] }
          let!(:other_product) { Fabricate :product, categories: [category] }

          it 'return all categories' do
            params = { page: nil, per_page: nil }
            response = group_api.call(:index, params)
            expected_return =
              [
                {
                  id: group.id,
                  name: group.name,
                  members_count: group.members.count,
                  higgles_count: group.higgles.count,
                  group_type: group.group_type,
                  products: group.products.popular.map { |product| { id: product.id, product_image: product.picture.big.url } },
                  leader_name: group.leader_name
                }
              ]
            expect(response[0]).to eq 200
            expect(response[2]).to eq [expected_return.to_json]
          end
        end
      end

      context 'two groups' do
        let(:category) { Fabricate :category }
        let!(:product) { Fabricate :product, categories: [category] }
        let(:other_category) { Fabricate :category }
        let!(:other_product) { Fabricate :product, categories: [other_category] }
        context 'order by name asc' do
          let!(:group) { Fabricate :group, categories: [category], name: 'zzzz' }
          let!(:other_group) { Fabricate :group, categories: [other_category], name: 'aaaa' }

          it 'returns the groups ordered by name ascending' do
            params = { page: nil, per_page: nil }
            response = group_api.call(:index, params)

            expected_return =
              [
                {
                  id: other_group.id,
                  name: other_group.name,
                  members_count: other_group.members.count,
                  higgles_count: other_group.higgles.count,
                  group_type: other_group.group_type,
                  products: other_group.products.map { |product| { id: product.id, product_image: product.picture.big.url } },
                  leader_name: other_group.leader_name
                },
                {
                  id: group.id,
                  name: group.name,
                  members_count: group.members.count,
                  higgles_count: group.higgles.count,
                  group_type: group.group_type,
                  products: group.products.map { |product| { id: product.id, product_image: product.picture.big.url } },
                  leader_name: group.leader_name
                }
              ]
            expect(response[0]).to eq 200
            expect(response[2]).to eq [expected_return.to_json]
          end
        end
      end
    end

    context 'the last 3 most popular' do
      let!(:category) { Fabricate :category }
      let!(:group) { Fabricate :group, categories: [category] }
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
          response = group_api.call(:index, params)
          expected_return =
            [
              {
                id: group.id,
                name: group.name,
                members_count: group.members.count,
                higgles_count: group.higgles.count,
                group_type: group.group_type,
                products: [
                  { id: first.id, product_image: first.picture.big.url },
                  { id: second.id, product_image: second.picture.big.url },
                  { id: third.id, product_image: third.picture.big.url }
                ],
                leader_name: group.leader_name
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
          response = group_api.call(:index, params)
          expected_return =
            [
              {
                id: group.id,
                name: group.name,
                members_count: group.members.count,
                higgles_count: group.higgles.count,
                group_type: group.group_type,

                products: [
                  { id: third.id, product_image: third.picture.big.url },
                  { id: first.id, product_image: first.picture.big.url },
                  { id: second.id, product_image: second.picture.big.url }
                ],
                leader_name: group.leader_name
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
          response = group_api.call(:index, params)
          expected_return =
            [
              {
                id: group.id,
                name: group.name,
                members_count: group.members.count,
                higgles_count: group.higgles.count,
                group_type: group.group_type,
                products: [
                  { id: forth.id, product_image: forth.picture.big.url },
                  { id: third.id, product_image: third.picture.big.url },
                  { id: first.id, product_image: first.picture.big.url }
                ],
                leader_name: group.leader_name
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end

      context 'with four products, and the first not available and the others availables' do
        let!(:first) { Fabricate(:product, merchant: merchant, categories: [category], has_quantity_available: false) }
        let!(:second) { Fabricate(:product, merchant: merchant, categories: [category], has_quantity_available: true) }
        let!(:third) { Fabricate(:product, merchant: merchant, categories: [category], has_quantity_available: true) }
        let!(:forth) { Fabricate(:product, merchant: merchant, categories: [category], has_quantity_available: true) }
        before do
          2.times { Fabricate(:higgle, product: first) }
          5.times { Fabricate(:higgle, product: third) }
          12.times { Fabricate(:higgle, product: forth) }
          Fabricate(:higgle, product: second)
        end
        it 'returns the most popular products' do
          params = { page: nil, per_page: nil }
          response = group_api.call(:index, params)
          expected_return =
            [
              {
                id: group.id,
                name: group.name,
                members_count: group.members.count,
                higgles_count: group.higgles.count,
                group_type: group.group_type,
                products: [
                  { id: forth.id, product_image: forth.picture.big.url },
                  { id: third.id, product_image: third.picture.big.url },
                  { id: second.id, product_image: second.picture.big.url }
                ],
                leader_name: group.leader_name
              }
            ]
          expect(response[0]).to eq 200
          expect(response[2]).to eq [expected_return.to_json]
        end
      end
    end
  end

  describe '#join' do
    let(:group) { Fabricate(:group) }

    context 'unauthenticated' do
      it 'responds 404' do
        response = group_api.call(:join, { group_id: group.id })
        expect(response).to be_404
      end
    end

    context 'authenticated' do
      let(:user) { Fabricate(:user) }
      let(:params) { { 'auth_token' => user.auth_token } }

      context 'when group not found' do
        it 'responds 404' do
          response = group_api.call(:join, params.merge(group_id: '999'))
          expect(response).to be_404
        end
      end

      context 'when group found' do

        context 'and no difference to catch parameter as symbol or string' do
          context 'with parameter as symbol' do
            it 'calls join method in group' do
              group = Fabricate(:group)
              expect_any_instance_of(Group).to receive(:join!).with(user).and_call_original
              response = group_api.call(:join, params.merge(group_id: group.id))
              expect(response).to be_200
            end
          end

          context 'with parameter as string' do
            it 'calls join method in group' do
              group = Fabricate(:group)
              expect_any_instance_of(Group).to receive(:join!).with(user).and_call_original
              response = group_api.call(:join, params.merge('group_id' => group.id))
              expect(response).to be_200
            end
          end
        end

        context 'and is public' do
          it 'joins group' do
            group = Fabricate(:group)
            expect_any_instance_of(Group).to receive(:join!).with(user).and_call_original
            response = group_api.call(:join, params.merge(group_id: group.id))
            expect(response).to be_200
          end
        end

        context 'and is private' do
          it 'responds 404' do
            private_group = Fabricate(:private_group)
            response = group_api.call(:join, params.merge(group_id: private_group.id))
            expect(response).to be_404
          end
        end
      end
    end
  end

  describe '#leave' do
    let(:group) { Fabricate(:group) }

    context 'unauthenticated' do
      it 'responds 404' do
        response = group_api.call(:leave, { group_id: group.to_param })
        expect(response).to be_404
      end
    end

    context 'authenticated' do
      let(:user) { Fabricate(:user) }
      let(:params) { { 'auth_token' => user.auth_token } }

      context 'when group not found' do
        it 'responds 404' do
          response = group_api.call(:leave, params.merge(group_id: '999'))
          expect(response).to be_404
        end
      end

      context 'and no difference to catch parameter as symbol or string' do
        context 'with parameter as symbol' do
          it 'calls leave method in group' do
            group = Fabricate(:group)
            expect_any_instance_of(Group).to receive(:leave!).with(user).and_call_original
            response = group_api.call(:leave, params.merge(group_id: group.id))
            expect(response).to be_200
          end
        end

        context 'with parameter as string' do
          it 'calls leave method in group' do
            group = Fabricate(:group)
            expect_any_instance_of(Group).to receive(:leave!).with(user).and_call_original
            response = group_api.call(:leave, params.merge('group_id' => group.id))
            expect(response).to be_200
          end
        end
      end

      context 'when user is part of the group' do
        it 'leaves group' do
          Fabricate(:groups_user, group: group, user: user)
          expect(group.reload.member?(user)).to eq true

          response = group_api.call(:leave, params.merge(group_id: group.id))

          expect(response).to be_200
          expect(group.reload.member?(user)).to eq false
        end
      end

      context 'when user is not part of the group' do
        it 'responds ok doing nothing' do
          response = group_api.call(:leave, params.merge(group_id: group.id))
          expect(response).to be_200
        end
      end
    end
  end
end

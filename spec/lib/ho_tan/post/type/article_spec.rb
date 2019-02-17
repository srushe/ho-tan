# frozen_string_literal: true

require_relative '../../../../../lib/ho_tan/post/type/article'
require 'timecop'

RSpec.describe HoTan::Post::Type::Article do
  let(:base_data) do
    {
      'type' => ['h-entry'],
      'properties' => {
        'context' => ['Hello'],
        'name' => ['The title of the article'],
        'published' => ['2019-02-07T12:34:56+00:00']
      }
    }
  end
  let(:data) { base_data }

  context '.slug' do
    subject(:instance) { described_class.new(data) }

    context 'when an "mp-slug" is set' do
      let(:mp_slug) { 'my-slug' }
      let(:data) do
        data = base_data.dup
        data['properties']['mp-slug'] = [mp_slug]
        data
      end

      it { expect(instance.slug).to eq(mp_slug) }
    end

    context 'when an "mp-slug" is not set' do
      context 'but a "name" is provided' do
        it { expect(instance.slug).to eq('the-title-of-the-article') }
      end

      context 'and a "name" is not provided' do
        let(:data) do
          data = base_data.dup
          data['properties'].delete('name')
          data['properties'].delete('published') if published.nil?
          data
        end
        let(:published) { base_data['properties']['published'][0] }

        context 'but "published" is set' do
          it { expect(instance.slug).to eq('123456') }
        end

        context 'and "published" is not set' do
          let(:published) { nil }

          before { Timecop.freeze(Time.parse('2019-01-07 23:45:01 UTC')) }
          after { Timecop.return }

          it { expect(instance.slug).to eq('234501') }
        end
      end
    end
  end
end

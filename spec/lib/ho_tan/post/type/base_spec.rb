# frozen_string_literal: true

require_relative '../../../../../lib/ho_tan/post/type/base'
require 'timecop'

class Mcguffin < HoTan::Post::Type::Base
end

RSpec.describe HoTan::Post::Type::Base do
  let(:base_data) do
    {
      'type' => ['h-entry'],
      'properties' => {
        'context' => ['Hello'],
        'published' => ['2019-02-07T12:34:56+00:00']
      }
    }
  end

  context '#new' do
    subject(:instance) { Mcguffin.new(base_data) }

    let(:expected_data) do
      expected = base_data.dup
      expected['properties'].merge('entry_type' => ['mcguffin'])
      expected
    end

    it 'saves the provided data with expected additions' do
      expect(instance.data).to eq(expected_data)
    end
  end

  context '.path' do
    subject(:instance) { Mcguffin.new(base_data) }

    it { expect(instance.path).to eq('mcguffins/2019/02/07') }
  end

  context '.slug' do
    subject(:instance) { Mcguffin.new(data) }

    let(:data) do
      data = base_data.dup
      data['properties']['mp-slug'] = [mp_slug] unless mp_slug.nil?
      data['properties'].delete('published') if published.nil?
      data
    end
    let(:published) { base_data['properties']['published'][0] }

    context 'when an "mp-slug" is set' do
      let(:mp_slug) { 'my-slug' }

      it { expect(instance.slug).to eq(mp_slug) }
    end

    context 'when an "mp-slug" is not set' do
      let(:mp_slug) { nil }

      context 'but published is set' do
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

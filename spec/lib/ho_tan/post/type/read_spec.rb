# frozen_string_literal: true

require_relative '../../../../../lib/ho_tan/post/type/read'

RSpec.describe HoTan::Post::Type::Read do
  let(:base_data) do
    {
      'type' => ['h-entry'],
      'properties' => {
        'context' => ['Hello'],
        'published' => ['2019-02-07T12:34:56+00:00']
      }
    }
  end

  context '.path' do
    subject(:instance) { described_class.new(base_data) }

    it { expect(instance.path).to eq('reading/2019/02/07') }
  end
end

# frozen_string_literal: true

require_relative '../../../lib/ho_tan/destination'

RSpec.describe HoTan::Destination do
  context '#new' do
    subject(:destination) { described_class.new(data) }

    let(:data) do
      {
        'uid' => 'some-identifier',
        'name' => 'Some Name',
        'directory' => 'some/path',
        'base-url' => 'https://example.com/',
        'default' => default
      }.compact
    end
    let(:default) { nil }

    it { expect(destination.to_config).to eq(data.slice('uid', 'name')) }

    context 'when the destination has a default field provided' do
      context 'and the value is "true"' do
        let(:default) { true }

        it { expect(destination.uid).to eq(data['uid']) }
        it { expect(destination.name).to eq(data['name']) }
        it { expect(destination.directory).to eq(data['directory']) }
        it { expect(destination.base_url).to eq(data['base_url']) }
        it { expect(destination.default?).to be true }
      end

      context 'and the value is "false"' do
        let(:default) { false }

        it { expect(destination.uid).to eq(data['uid']) }
        it { expect(destination.name).to eq(data['name']) }
        it { expect(destination.directory).to eq(data['directory']) }
        it { expect(destination.base_url).to eq(data['base_url']) }
        it { expect(destination.default?).to be false }
      end
    end

    context 'when the destination has no default field provided' do
      it { expect(destination.uid).to eq(data['uid']) }
      it { expect(destination.name).to eq(data['name']) }
      it { expect(destination.directory).to eq(data['directory']) }
      it { expect(destination.base_url).to eq(data['base_url']) }
      it { expect(destination.default?).to be false }
    end
  end
end

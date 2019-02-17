# frozen_string_literal: true

require_relative '../../../lib/ho_tan/destinations'

RSpec.describe HoTan::Destinations do
  let(:data) do
    [
      {
        'uid' => 'https://first-site.example.com/',
        'name' => 'Site 1',
        'directory' => 'data/site/1',
        'base_url' => 'https://first-site.example.com/'
      },
      {
        'uid' => 'https://second-site.example.com/',
        'name' => 'Site 2',
        'directory' => 'data/site/2',
        'base_url' => 'https://second-site.example.com/'
      },
      {
        'uid' => 'https://third-site.example.com/',
        'name' => 'Site 3',
        'directory' => 'data/site/3',
        'base_url' => 'https://third-site.example.com/'
      }
    ]
  end
  let(:destinations) { described_class.from(data) }

  context '#from' do
    before do
      allow(HoTan::Destination).to receive(:new).and_call_original

      destinations
    end

    it 'creates each destination' do
      aggregate_failures do
        expect(HoTan::Destination).to have_received(:new).with(data[0]).once
        expect(HoTan::Destination).to have_received(:new).with(data[1]).once
        expect(HoTan::Destination).to have_received(:new).with(data[2]).once
      end
    end
  end

  context '.all' do
    let(:site_1) { instance_double(HoTan::Destination) }
    let(:site_2) { instance_double(HoTan::Destination) }
    let(:site_3) { instance_double(HoTan::Destination) }

    before do
      allow(HoTan::Destination).to receive(:new).with(data[0]) { site_1 }
      allow(HoTan::Destination).to receive(:new).with(data[1]) { site_2 }
      allow(HoTan::Destination).to receive(:new).with(data[2]) { site_3 }

      destinations
    end

    it { expect(destinations.all).to eq([site_1, site_2, site_3]) }
  end

  context '.to_config' do
    before { destinations }

    let(:expected_config) do
      [
        { 'uid' => 'https://first-site.example.com/', 'name' => 'Site 1' },
        { 'uid' => 'https://second-site.example.com/', 'name' => 'Site 2' },
        { 'uid' => 'https://third-site.example.com/', 'name' => 'Site 3' }
      ]
    end

    it { expect(destinations.to_config).to eq(expected_config) }
  end

  context '.default' do
    let(:site_1) { instance_double(HoTan::Destination, default?: false) }
    let(:site_2) { instance_double(HoTan::Destination, default?: is_default) }
    let(:site_3) { instance_double(HoTan::Destination, default?: false) }

    before do
      allow(HoTan::Destination).to receive(:new).with(data[0]) { site_1 }
      allow(HoTan::Destination).to receive(:new).with(data[1]) { site_2 }
      allow(HoTan::Destination).to receive(:new).with(data[2]) { site_3 }

      destinations
    end

    context 'when a default is explicitly set' do
      let(:is_default) { true }

      it { expect(destinations.default).to eq(site_2) }
    end

    context 'when no default is explicitly set' do
      let(:is_default) { false }

      it { expect(destinations.default).to eq(site_1) }
    end
  end
end

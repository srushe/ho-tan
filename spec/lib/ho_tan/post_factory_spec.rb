# frozen_string_literal: true

require_relative '../../../lib/ho_tan/destinations'
require_relative '../../../lib/ho_tan/post_factory'

RSpec.describe HoTan::PostFactory do
  let(:destination_data) do
    [
      {
        'uid' => 'site_1',
        'name' => 'Site 1',
        'directory' => 'data/site/1',
        'base_url' => 'https://first-site.example.com/'
      },
      {
        'uid' => 'site_2',
        'name' => 'Site 2',
        'directory' => 'data/site/2',
        'base_url' => 'https://second-site.example.com/'
      },
      {
        'uid' => 'site_3',
        'name' => 'Site 3',
        'directory' => 'data/site/3',
        'base_url' => 'https://third-site.example.com/'
      }
    ]
  end
  let(:destinations) do
    HoTan::Destinations.from(destination_data)
  end

  context '#new' do
    subject(:post_factory) do
      described_class.new(destinations: destinations)
    end

    it { expect(post_factory.destinations).to eq(destinations) }
  end

  context '.create' do
    subject(:create) do
      described_class.new(destinations: destinations).create(data)
    end

    let(:data) { double(:some_data) }
    let(:normalized_data) do
      {
        'type' => ['h-entry'],
        'properties' => {
          'mp-destination' => mp_destination
        }.compact
      }
    end
    let(:normalized_data_excluding_destination) do
      {
        'type' => ['h-entry'],
        'properties' => {}
      }
    end

    before do
      allow(HoTan::Post::Normalize).to receive(:for_create) { normalized_data }
      allow(HoTan::Post).to receive(:create!)
    end

    context 'when mp-destination is not provided' do
      let(:mp_destination) { nil }

      before { create }

      it { expect(HoTan::Post::Normalize).to have_received(:for_create).with(data) }
      it { expect(HoTan::Post).to have_received(:create!).with(normalized_data_excluding_destination, destinations.default) }
    end

    context 'when mp-destination is provided' do
      context 'and is in the destinations list' do
        let(:mp_destination) { [destination_data[2]['uid']] }

        before { create }

        it { expect(HoTan::Post::Normalize).to have_received(:for_create).with(data) }
        it { expect(HoTan::Post).to have_received(:create!).with(normalized_data_excluding_destination, destinations.all[2]) }
      end

      context 'but is not in the destinations list' do
        let(:mp_destination) { 'non-existent' }

        it 'normalizes the data' do
          begin create rescue nil end
          expect(HoTan::Post::Normalize).to have_received(:for_create).with(data)
        end

        it 'does not attempt to create the post' do
          begin create rescue nil end
          expect(HoTan::Post).not_to have_received(:create!)
        end

        it { expect { create }.to raise_error(HoTan::PostFactory::UnrecognisedDestinationError) }
      end
    end
  end

  context '.from' do
    subject(:from) do
      described_class.new(destinations: destinations).from(url)
    end

    let(:location) { instance_double(HoTan::Post::Location) }

    before do
      allow(HoTan::Post::Location).to receive(:new) { location }
      allow(location).to receive(:path_for_url) { path }
      allow(HoTan::Post).to receive(:retrieve)
    end

    context 'when the url matches one of the destinations' do
      let(:url) { 'https://third-site.example.com/foo/bar/baz' }
      let(:path) { 'a/path/that/is/totally/real' }
      let(:expected_destination) { destinations.all[2] }

      context 'and no error occurs when retrieving the post' do
        before { from }

        it 'retrieves the post with the correct details' do
          aggregate_failures do
            expect(HoTan::Post::Location).to have_received(:new).with(expected_destination)
            expect(location).to have_received(:path_for_url).with(url)
            expect(HoTan::Post).to have_received(:retrieve).with(path, url, expected_destination)
          end
        end
      end

      context 'but an error occurs when retrieving the post' do
        before do
          allow(HoTan::Post).to receive(:retrieve).and_raise(HoTan::Post::InvalidPathError)
        end

        it 'attempts to read the file' do
          begin from rescue nil end
          aggregate_failures do
            expect(HoTan::Post::Location).to have_received(:new).with(expected_destination)
            expect(location).to have_received(:path_for_url).with(url)
            expect(HoTan::Post).to have_received(:retrieve).with(path, url, expected_destination)
          end
        end

        it 'raises an appropriate error' do
          expect { from }.to raise_error(HoTan::PostFactory::InvalidPathError)
        end
      end
    end

    context 'when the url does not match one of the destinations' do
      let(:url) { 'https://fourth-site.example.com/foo/bar/baz' }

      it { expect { from }.to raise_error(HoTan::PostFactory::UnrecognisedDestinationError) }
      it 'does not try to determine the post location' do
        begin from rescue nil end
        expect(HoTan::Post::Location).not_to have_received(:new)
      end
      it 'does not try to retrieve the post' do
        expect(HoTan::Post).not_to have_received(:retrieve)
      end
    end
  end
end

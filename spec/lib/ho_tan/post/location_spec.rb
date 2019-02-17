# frozen_string_literal: true

require_relative '../../../../lib/ho_tan/post/location'
require_relative '../../../../lib/ho_tan/destination'

RSpec.describe HoTan::Post::Location do
  let(:destination) do
    HoTan::Destination.new('uid' => 'test-site',
                           'name' => 'A Test Site',
                           'directory' => '/some/place/files/live',
                           'base_url' => 'https://test.example.com/')
  end

  context '#new' do
    subject(:location) { described_class.new(destination) }

    it 'creates an instance with the appropriate data' do
      expect(location).to be_an_instance_of(described_class)
      expect(location.destination).to eq(destination)
    end
  end

  context '.url_for_instance' do
    subject(:url_for_instance) { location.url_for_instance(instance) }

    let(:location) { described_class.new(destination) }
    let(:instance) do
      double(:a_post_instance, path: 'some/path/to/files', slug: 'a-file')
    end
    let(:expected_url) { 'https://test.example.com/some/path/to/files/a-file' }

    it { expect(url_for_instance).to eq(expected_url) }
  end

  context '.path_for_instance' do
    subject(:path_for_instance) { location.path_for_instance(instance) }

    let(:location) { described_class.new(destination) }
    let(:instance) do
      double(:a_post_instance, path: 'some/path/to/files', slug: 'a-file')
    end
    let(:expected_path) { '/some/place/files/live/some/path/to/files/a-file.json' }

    it { expect(path_for_instance).to eq(expected_path) }
  end

  context '.path_for_url' do
    subject(:path_for_url) { location.path_for_url(url) }

    let(:location) { described_class.new(destination) }
    let(:url) { 'https://test.example.com/some/path/to/files/a-file' }
    let(:expected_path) { '/some/place/files/live/some/path/to/files/a-file.json' }

    it { expect(path_for_url).to eq(expected_path) }
  end
end

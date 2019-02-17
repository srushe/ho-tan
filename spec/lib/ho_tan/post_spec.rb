# frozen_string_literal: true

require_relative '../../../lib/ho_tan/post'
require_relative '../../../lib/ho_tan/destination'
require 'indieweb/post_types'
require 'timecop'

RSpec.shared_examples_for 'a valid update' do
  let(:updated_url) { false }

  before do
    allow(post).to receive(:updated_url?) { updated_url }
  end

  it 'updates the properties and saves the data' do
    post.update!(update_data)
    expect(post.instance.properties).to eq(expected_properties)
    expect(post).to have_received(:save!)
  end

  context 'deleting out-dated data files' do
    let(:location) { instance_double(HoTan::Post::Location) }
    let(:original_path) { 'a/path/to/data/for/a/now/deleted/post.json' }
    let(:original_data_file) { instance_double(HoTan::Post::DataFile) }

    before do
      allow(HoTan::Post::Location).to receive(:new) { location }
      allow(location).to receive(:path_for_url) { original_path }
      allow(HoTan::Post::DataFile).to receive(:new).with(original_path) { original_data_file }
      allow(original_data_file).to receive(:delete!)
      post.update!(update_data)
    end

    context 'when the url has not changed' do
      it 'does not attempt to delete the data file' do
        aggregate_failures do
          expect(location).not_to have_received(:path_for_url)
          expect(HoTan::Post::DataFile).not_to have_received(:new).with(original_path)
          expect(original_data_file).not_to have_received(:delete!)
        end
      end
    end

    context 'when the url has changed' do
      let(:updated_url) { true }

      it 'attempts to delete the data file' do
        aggregate_failures do
          expect(location).to have_received(:path_for_url)
          expect(HoTan::Post::DataFile).to have_received(:new).with(original_path)
          expect(original_data_file).to have_received(:delete!)
        end
      end
    end
  end
end

RSpec.shared_examples_for 'an invalid replace or add update' do |update_type|
  context 'when an error occurs' do
    let(:update_data) do
      {
        'action' => 'update',
        'url' => url,
        update_type => actual_update_data
      }
    end

    context 'when the update data is not a hash' do
      let(:actual_update_data) { [] }

      it { expect { post.update!(update_data) }.to raise_error(HoTan::Post::InvalidUpdateError) }
    end

    context 'when the update data is a hash' do
      context 'but not all of the values are arrays' do
        let(:actual_update_data) do
          {
            'foo' => ['bar'],
            'cthulhu' => 'fhtagn'
          }
        end

        it { expect { post.update!(update_data) }.to raise_error(HoTan::Post::InvalidUpdateError) }
      end
    end
  end
end

RSpec.describe HoTan::Post do
  let(:data_file) { instance_double(HoTan::Post::DataFile) }
  let(:destination) do
    HoTan::Destination.new('uid' => 'test-site',
                           'name' => 'A Test Site',
                           'directory' => '/some/place/files/live',
                           'base_url' => 'https://test.example.com/')
  end
  let(:data) do
    {
      'type' => ['h-entry'],
      'properties' => {
        'entry_type' => [post_type],
        'content' => ['Some content']
      }
    }
  end
  let(:post_type_class) do
    %w[Article Bookmark Checkin Note Photo Read Reply Repost].sample
  end
  let(:post_type_full_class) do
    Object.const_get("HoTan::Post::Type::#{post_type_class}")
  end
  let(:post_instance) do
    instance_double(post_type_full_class, data: data)
  end
  let(:post_type) { post_type_class.downcase }

  before do
    allow(Indieweb::PostTypes).to receive(:type_from) { post_type }
    allow(HoTan::Post::DataFile).to receive(:new) { data_file }
    allow(data_file).to receive(:save) { true }
  end

  context '#create!' do
    let(:save_location) { 'path/to/a/file' }

    before do
      allow(File).to receive(:exist?) { file_exists }
      allow(post_type_full_class).to receive(:new) { post_instance }
      allow_any_instance_of(described_class).to receive(:save!).and_call_original
      allow_any_instance_of(described_class).to receive(:save_location) { save_location }
    end

    context 'when the post type is a supported one' do
      subject(:post) { described_class.create!(data, destination) }

      context 'and the post does not already exist' do
        let(:file_exists) { false }

        before { post }

        it 'correctly creates and attempts to save the post' do
          aggregate_failures do
            expect(Indieweb::PostTypes).to have_received(:type_from).with(data)
            expect(post_type_full_class).to have_received(:new).with(data)
            expect(File).to have_received(:exist?).with(save_location)
            expect(post).to have_received(:save!)
            expect(HoTan::Post::DataFile).to have_received(:new).with('path/to/a/file')
            expect(data_file).to have_received(:save).with(post_instance.data)
            expect(post).to be_an_instance_of(described_class)
            expect(post.destination).to eq(destination)
          end
        end
      end

      context 'but the post already exists' do
        let(:file_exists) { true }

        it 'correctly creates and attempts to save the post' do
          begin post rescue nil end

          aggregate_failures do
            expect(Indieweb::PostTypes).to have_received(:type_from).with(data)
            expect(post_type_full_class).to have_received(:new).with(data)
            expect(File).to have_received(:exist?).with(save_location)
            expect(HoTan::Post::DataFile).not_to have_received(:new)
            expect(data_file).not_to have_received(:save)
          end
        end

        it { expect { post }.to raise_error(HoTan::Post::DuplicateCreateError) }
      end
    end

    context 'when the post type is not a supported one' do
      let(:post_type) { 'nope' }
      let(:post) { described_class.create!(data, destination) }

      it 'attempts to determine the post type' do
        begin post rescue nil end
        expect(Indieweb::PostTypes).to have_received(:type_from).with(data)
      end

      it 'raises an error when the post type is not recognised' do
        expect { post }.to raise_error(HoTan::Post::UnrecognisedTypeError)
      end
    end
  end

  context '#retrieve' do
    subject(:post) { described_class.retrieve(path, url, destination) }

    let(:path) { 'a/path/to/a/file.json' }
    let(:url) { 'https://test.example.com/foo/bar/baz' }

    before do
      allow(post_type_full_class).to receive(:new) { post_instance }
      allow(data_file).to receive(:read) { data }
    end

    context 'when the path exists' do
      before { post }

      it 'correctly retrieves the post' do
        aggregate_failures do
          expect(HoTan::Post::DataFile).to have_received(:new).with(path)
          expect(data_file).to have_received(:read)
          expect(Indieweb::PostTypes).to have_received(:type_from).with(data)
          expect(post_type_full_class).to have_received(:new).with(data)
          expect(post).to be_an_instance_of(described_class)
          expect(post.destination).to eq(destination)
          expect(post.original_url).to eq(url)
        end
      end
    end

    context 'when the path does not exist' do
      before do
        allow(data_file).to receive(:read).and_raise(HoTan::Post::DataFile::NotFoundError)
      end

      it 'only attempts to retrieve the post' do
        begin post rescue nil end
        aggregate_failures do
          expect(HoTan::Post::DataFile).to have_received(:new).with(path)
          expect(data_file).to have_received(:read)
          expect(Indieweb::PostTypes).not_to have_received(:type_from)
          expect(post_type_full_class).not_to have_received(:new)
        end
      end

      it 'raises an error' do
        expect { post }.to raise_error(HoTan::Post::InvalidPathError)
      end
    end
  end

  context '.update!' do
    subject(:post) { described_class.retrieve(path, url, destination) }

    let(:post_instance) { post_type_full_class.new(data) }
    let(:path) { 'a/path/to/a/file.json' }
    let(:url) { 'https://test.example.com/foo/bar/baz' }
    let(:data) do
      {
        'type' => 'h-entry',
        'properties' => {
          'content' => ['Some content'],
          'syndication' => ['http://some-site.com/123'],
          'tags' => %w[foo bar baz]
        }
      }
    end

    before do
      allow(data_file).to receive(:read) { data }
      allow(post).to receive(:save!) { true }
      Timecop.freeze(Time.parse('2019-02-11 12:34:56 UTC'))
    end

    after { Timecop.return }

    context 'when properties are to be replaced' do
      let(:update_data) do
        {
          'action' => 'update',
          'url' => url,
          'replace' => {
            'content' => ['hello moon'],
            'name' => ['wibble']
          }
        }
      end
      let(:expected_properties) do
        {
          'entry_type' => [post_type],
          'content' => ['hello moon'],
          'name' => ['wibble'],
          'syndication' => ['http://some-site.com/123'],
          'tags' => %w[foo bar baz],
          'updated_at' => ['2019-02-11T12:34:56Z']
        }
      end

      it_behaves_like 'a valid update'
      it_behaves_like 'an invalid replace or add update', 'replace'
    end

    context 'when properties are to be added' do
      let(:update_data) do
        {
          'action' => 'update',
          'url' => url,
          'add' => {
            'syndication' => ['http://some-other-site.com/456'],
            'name' => ['fhtagn']
          }
        }
      end
      let(:expected_properties) do
        {
          'entry_type' => [post_type],
          'content' => ['Some content'],
          'name' => ['fhtagn'],
          'syndication' => ['http://some-site.com/123', 'http://some-other-site.com/456'],
          'tags' => %w[foo bar baz],
          'updated_at' => ['2019-02-11T12:34:56Z']
        }
      end

      it_behaves_like 'a valid update'
      it_behaves_like 'an invalid replace or add update', 'add'
    end

    context 'when properties are to be deleted' do
      context 'and the properties are to be deleted completely' do
        let(:update_data) do
          {
            'action' => 'update',
            'url' => url,
            'delete' => %w[name syndication]
          }
        end
        let(:expected_properties) do
          {
            'entry_type' => [post_type],
            'content' => ['Some content'],
            'tags' => %w[foo bar baz],
            'updated_at' => ['2019-02-11T12:34:56Z']
          }
        end

        it_behaves_like 'a valid update'
      end

      context 'and the properties are to be partially deleted' do
        let(:update_data) do
          {
            'action' => 'update',
            'url' => url,
            'delete' => {
              'tags' => ['bar']
            }
          }
        end
        let(:expected_properties) do
          {
            'entry_type' => [post_type],
            'content' => ['Some content'],
            'syndication' => ['http://some-site.com/123'],
            'tags' => %w[foo baz],
            'updated_at' => ['2019-02-11T12:34:56Z']
          }
        end

        it_behaves_like 'a valid update'
      end

      context 'when an error occurs' do
        let(:update_data) do
          {
            'action' => 'update',
            'url' => url,
            'delete' => delete_data
          }
        end

        context 'when the update data is not a hash or an array' do
          let(:delete_data) { '' }

          it { expect { post.update!(update_data) }.to raise_error(HoTan::Post::InvalidUpdateError) }
        end

        context 'when the update data is a hash' do
          context 'but not all of the values are arrays' do
            let(:delete_data) do
              {
                'foo' => ['bar'],
                'cthulhu' => 'fhtagn'
              }
            end

            it { expect { post.update!(update_data) }.to raise_error(HoTan::Post::InvalidUpdateError) }
          end
        end
      end
    end

    context 'when all types of changes are provided' do
      let(:update_data) do
        {
          'action' => 'update',
          'url' => url,
          'replace' => {
            'content' => ['hello moon']
          },
          'add' => {
            'syndication' => ['http://some-other-site.com/456'],
            'name' => ['fhtagn']
          },
          'delete' => ['tags']
        }
      end
      let(:expected_properties) do
        {
          'entry_type' => [post_type],
          'content' => ['hello moon'],
          'name' => ['fhtagn'],
          'syndication' => ['http://some-site.com/123', 'http://some-other-site.com/456'],
          'updated_at' => ['2019-02-11T12:34:56Z']
        }
      end

      it_behaves_like 'a valid update'
    end
  end

  context '.delete!' do
    let(:path) { 'a/path/to/a/file.json' }
    let(:url) { 'https://test.example.com/foo/bar/baz' }
    let(:post) do
      described_class.retrieve(path, url, destination)
    end
    let(:expected_deleted_at) { '2019-02-11T12:34:56Z' }

    before do
      allow(post_type_full_class).to receive(:new) { post_instance }
      allow(data_file).to receive(:read) { data }
      allow(post).to receive(:save!) { true }
      allow(post_instance).to receive(:properties) { data['properties'] }
      Timecop.freeze(Time.parse('2019-02-11 12:34:56 UTC'))

      post.delete!
    end

    after { Timecop.return }

    it 'correctly marks the post as deleted' do
      expect(post).to have_received(:save!)
      expect(post.instance.properties).to have_key('deleted_at')
      expect(post.instance.properties['deleted_at']).to eq([expected_deleted_at])
    end
  end

  context '.undelete!' do
    let(:path) { 'a/path/to/a/file.json' }
    let(:url) { 'https://test.example.com/foo/bar/baz' }
    let(:deleted_post) do
      described_class.retrieve(path, url, destination)
    end
    let(:data) do
      {
        'type' => ['h-entry'],
        'properties' => {
          'content' => ['Some content'],
          'deleted_at' => ['2019-02-11 12:34:56 UTC']
        }
      }
    end

    before do
      allow(post_type_full_class).to receive(:new) { post_instance }
      allow(data_file).to receive(:read) { data }
      allow(deleted_post).to receive(:save!) { true }
      allow(post_instance).to receive(:properties) { data['properties'] }

      deleted_post.undelete!
    end

    it 'correctly marks the post as undeleted' do
      expect(deleted_post).to have_received(:save!)
      expect(deleted_post.instance.properties).not_to have_key('deleted_at')
    end
  end

  context '.save_location' do
    let(:post) { described_class.create!(data, destination) }
    let(:save_location) { post.save_location }

    before do
      allow(post_type_full_class).to receive(:new) { post_instance }
      allow(destination).to receive(:directory).and_call_original
      allow(post_instance).to receive(:path) { 'some/path' }
      allow(post_instance).to receive(:slug) { 'a-slug' }
      allow_any_instance_of(described_class).to receive(:save!) { true }
    end

    it 'pulls the data from the appropriate places' do
      save_location

      aggregate_failures do
        expect(destination).to have_received(:directory)
        expect(post_instance).to have_received(:path)
        expect(post_instance).to have_received(:slug)
      end
    end

    it { expect(save_location).to eq('/some/place/files/live/some/path/a-slug.json') }
  end

  context '.absolute_url' do
    let(:post) { described_class.create!(data, destination) }
    let(:absolute_url) { post.absolute_url }

    before do
      allow(post_type_full_class).to receive(:new) { post_instance }
      allow(destination).to receive(:base_url).and_call_original
      allow(post_instance).to receive(:path) { 'some/path' }
      allow(post_instance).to receive(:slug) { 'a-slug' }
      allow_any_instance_of(described_class).to receive(:save!) { true }
    end

    it 'pulls the data from the appropriate places' do
      absolute_url

      aggregate_failures do
        expect(destination).to have_received(:base_url)
        expect(post_instance).to have_received(:path).twice
        expect(post_instance).to have_received(:slug).twice
      end
    end

    it { expect(absolute_url).to eq('https://test.example.com/some/path/a-slug') }
  end

  context '.updated_url?' do
    subject(:post) { described_class.retrieve(path, url, destination) }

    let(:path) { 'a/path/to/a/file.json' }
    let(:url) { 'https://test.example.com/foo/bar/baz' }

    let(:location) do
      instance_double(HoTan::Post::Location, url_for_instance: absolute_url)
    end

    before do
      allow(post_type_full_class).to receive(:new) { post_instance }
      allow(data_file).to receive(:read) { data }
      allow(HoTan::Post::Location).to receive(:new) { location }
    end

    context 'when there is no original url' do
      before do
        allow(post).to receive(:original_url) { nil }
      end

      it { expect(post.updated_url?).to be false }
    end

    context 'when there is an original url' do
      context 'and it matches the current url' do
        let(:absolute_url) { url }

        it { expect(post.updated_url?).to be false }
      end

      context 'and it does not match the current url' do
        let(:absolute_url) { 'https://test/example.com/some/other/place' }

        it { expect(post.updated_url?).to be true }
      end
    end
  end
end

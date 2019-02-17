# frozen_string_literal: true

require_relative '../../../lib/ho_tan/application'
require 'json'
require 'rspec'
require 'rack/test'

RSpec.shared_examples_for 'an error response' do
  let(:response_json) { JSON.parse(last_response.body) }

  it 'responds correctly' do
    aggregate_failures do
      expect(last_response.status).to eq(expected_status)
      expect(last_response.content_type).to eq('application/json')
      expect(response_json).to eq('error' => expected_error_type, 'error_description' => expected_error_description)
    end
  end
end

RSpec.shared_examples_for 'a request with missing destinations' do
  before do
    @original_destinations = described_class.settings.destinations
    described_class.set :destinations, []
    make_request
  end

  after do
    described_class.set :destinations, @original_destinations
  end

  it 'responds correctly' do
    aggregate_failures do
      expect(last_response.status).to eq(503)
      expect(last_response.content_type).to eq('text/html;charset=utf-8')
      expect(last_response.body).to eq('Destinations must be configured')
    end
  end
end

RSpec.shared_examples_for 'an endpoint requiring verification' do
  before do
    allow(IndieAuth::TokenVerification).to receive(:new).and_raise(error)

    make_request
  end

  context 'when verification raises AccessTokenMissingError' do
    let(:error) { IndieAuth::TokenVerification::AccessTokenMissingError }
    let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:unauthorized] }
    let(:expected_error_type) { 'unauthorized' }
    let(:expected_error_description) { 'Access token missing or empty' }

    it_behaves_like 'an error response'
  end

  context 'when verification raises MissingDomainError' do
    let(:error) { IndieAuth::TokenVerification::MissingDomainError }
    let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request] }
    let(:expected_error_type) { 'invalid_request' }
    let(:expected_error_description) { 'DOMAIN is not specified' }

    it_behaves_like 'an error response'
  end

  context 'when verification raises MissingTokenEndpointError' do
    let(:error) { IndieAuth::TokenVerification::MissingTokenEndpointError }
    let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request] }
    let(:expected_error_type) { 'invalid_request' }
    let(:expected_error_description) { 'TOKEN_ENDPOINT is not specified' }

    it_behaves_like 'an error response'
  end

  context 'when verification raises ForbiddenUserError' do
    let(:error) { IndieAuth::TokenVerification::ForbiddenUserError }
    let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:forbidden] }
    let(:expected_error_type) { 'forbidden' }
    let(:expected_error_description) { 'User does not have permission' }

    it_behaves_like 'an error response'
  end

  context 'when verification raises IncorrectMeError' do
    let(:error) { IndieAuth::TokenVerification::IncorrectMeError }
    let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:unauthorized] }
    let(:expected_error_type) { 'insufficient_scope' }
    let(:expected_error_description) { 'The "me" value does not match the expected DOMAIN' }

    it_behaves_like 'an error response'
  end

  context 'when verification raises InsufficentScopeError' do
    let(:error) { IndieAuth::TokenVerification::InsufficentScopeError }
    let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:unauthorized] }
    let(:expected_error_type) { 'insufficient_scope' }
    let(:expected_error_description) { 'The scope of this token does not meet the requirements for this request' }

    it_behaves_like 'an error response'
  end
end

RSpec.shared_examples_for 'an invalid create request' do
  let(:post_factory) { instance_double(HoTan::PostFactory) }
  let(:error_message) { nil }
  let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request] }
  let(:expected_error_type) { 'invalid_request' }

  before do
    allow(HoTan::PostFactory).to receive(:new) { post_factory }
    allow(post_factory).to receive(:create).and_raise(error, error_message)

    make_request
  end

  context 'when creation raises HoTan::Post::Normalize::InvalidHError' do
    let(:error) { HoTan::Post::Normalize::InvalidHError }
    let(:expected_error_description) { "'h' must be provided" }

    it_behaves_like 'an error response'
  end

  context 'when creation raises HoTan::Post::Normalize::InvalidTypeError' do
    let(:error) { HoTan::Post::Normalize::InvalidTypeError }
    let(:expected_error_description) { 'A type must be provided' }

    it_behaves_like 'an error response'
  end

  context 'when creation raises HoTan::Post::Normalize::InvalidCreateError' do
    let(:error) { HoTan::Post::Normalize::InvalidCreateError }
    let(:expected_error_description) { 'No recognisable parameters for entry creation' }

    it_behaves_like 'an error response'
  end

  context 'when creation raises HoTan::Post::UnrecognisedTypeError' do
    let(:error) { HoTan::Post::UnrecognisedTypeError }
    let(:error_message) { "The type 'wibble' is not recognised" }
    let(:expected_error_description) { error_message }

    it_behaves_like 'an error response'
  end

  context 'when creation raises HoTan::PostFactory::UnrecognisedDestinationError' do
    let(:error) { HoTan::PostFactory::UnrecognisedDestinationError }
    let(:expected_error_description) { 'An unrecognised destination was provided' }

    it_behaves_like 'an error response'
  end

  context 'when creation raises HoTan::Post::DuplicateCreateError' do
    let(:error) { HoTan::Post::DuplicateCreateError }
    let(:expected_error_description) { 'Failed to create due to an already existing entry' }

    it_behaves_like 'an error response'
  end
end

RSpec.shared_examples_for 'an invalid update request' do
  let(:post_factory) { instance_double(HoTan::PostFactory) }
  let(:error_message) { nil }
  let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request] }
  let(:expected_error_type) { 'invalid_request' }

  before do
    allow(HoTan::PostFactory).to receive(:new) { post_factory }
  end

  context 'when an error occurs while retrieving the post' do
    before do
      allow(post_factory).to receive(:from).and_raise(error, error_message)
      make_request
    end

    context 'when the request raises HoTan::Post::DataFile::NotFoundError' do
      let(:error) { HoTan::Post::DataFile::NotFoundError }
      let(:expected_error_description) { 'Post not found for provided URL' }

      it_behaves_like 'an error response'
    end

    context 'when the request raises HoTan::PostFactory::UnrecognisedDestinationError' do
      let(:error) { HoTan::PostFactory::UnrecognisedDestinationError }
      let(:expected_error_description) { 'An unrecognised destination was provided' }

      it_behaves_like 'an error response'
    end
  end

  context 'when the error occurs when updating the post' do
    let(:existing_post) { double(:post) }

    before do
      allow(post_factory).to receive(:from) { existing_post }
      allow(existing_post).to receive(:update!).and_raise(error, error_message)
      make_request
    end

    context 'when the request raises HoTan::Post::InvalidUpdateError' do
      let(:error) { HoTan::Post::InvalidUpdateError }
      let(:expected_error_description) { 'Invalid update parameters provided' }

      it_behaves_like 'an error response'
    end

    context 'when the request raises HoTan::PostFactory::UnrecognisedDestinationError' do
      let(:error) { HoTan::PostFactory::UnrecognisedDestinationError }
      let(:expected_error_description) { 'An unrecognised destination was provided' }

      it_behaves_like 'an error response'
    end

    context 'when the request raises HoTan::Post::UnrecognisedTypeError' do
      let(:error) { HoTan::Post::UnrecognisedTypeError }
      let(:expected_error_description) { "The type 'wibble' is not recognised" }
      let(:error_message) { "The type 'wibble' is not recognised" }

      it_behaves_like 'an error response'
    end
  end
end

RSpec.shared_examples_for 'an invalid delete or undelete request' do
  let(:post_factory) { instance_double(HoTan::PostFactory) }
  let(:error_message) { nil }
  let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request] }
  let(:expected_error_type) { 'invalid_request' }

  before do
    allow(HoTan::PostFactory).to receive(:new) { post_factory }
    allow(post_factory).to receive(:from).and_raise(error, error_message)

    make_request
  end

  context 'when the request raises HoTan::Post::DataFile::NotFoundError' do
    let(:error) { HoTan::Post::DataFile::NotFoundError }
    let(:expected_error_description) { 'Post not found for provided URL' }

    it_behaves_like 'an error response'
  end

  context 'when the request raises HoTan::PostFactory::UnrecognisedDestinationError' do
    let(:error) { HoTan::PostFactory::UnrecognisedDestinationError }
    let(:expected_error_description) { 'An unrecognised destination was provided' }

    it_behaves_like 'an error response'
  end
end

RSpec.describe HoTan::Application do
  include Rack::Test::Methods

  def app
    HoTan::Application
  end

  let(:should_verify) { false }
  let(:token_verifier) { instance_double(IndieAuth::TokenVerification) }

  before do
    allow(IndieAuth::TokenVerification).to receive(:new) { token_verifier }
    allow(token_verifier).to receive(:verify) { should_verify }
  end

  context 'GET' do
    context 'when the index is requested' do
      let(:make_request) { get '/' }

      it_behaves_like 'a request with missing destinations'

      it 'does not attempt to verify a token' do
        make_request
        expect(IndieAuth::TokenVerification).not_to have_received(:new)
      end

      it 'returns the default index page' do
        make_request
        aggregate_failures do
          expect(last_response).to be_ok
          expect(last_response.body).to match('<h1>Ho-Tan - A Micropub Endpoint</h1>')
        end
      end
    end

    context 'when an unrecognised "q" parameter is provided' do
      let(:make_request) { get '/?q=whowiththewhatnow' }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'

      context 'when verification succeeds' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request] }
        let(:expected_error_type) { 'invalid_request' }
        let(:expected_error_description) { "'whowiththewhatnow' is not a valid value for 'q'" }

        before { make_request }

        it_behaves_like 'an error response'
      end
    end

    context 'when q=destination is provided' do
      let(:make_request) { get '/?q=destination' }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'

      context 'when verification succeeds' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok] }
        let(:response_json) { JSON.parse(last_response.body) }
        let(:expected_response) do
          {
            'destination' => [
              { 'uid' => 'https://first-site.example.com/', 'name' => 'Site 1' },
              { 'uid' => 'https://second-site.example.com/', 'name' => 'Site 2' },
              { 'uid' => 'https://third-site.example.com/', 'name' => 'Site 3' }
            ]
          }
        end

        before { make_request }

        it 'responds correctly' do
          aggregate_failures do
            expect(last_response.status).to eq(expected_status)
            expect(last_response.content_type).to eq('application/json')
            expect(response_json).to eq(expected_response)
          end
        end
      end
    end

    context 'when q=syndicate-to is provided' do
      let(:make_request) { get '/?q=syndicate-to' }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'

      context 'when verification succeeds' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok] }
        let(:response_json) { JSON.parse(last_response.body) }
        let(:expected_response) do
          {
            'syndicate-to' => [
              { 'uid' => 'https://twitter.com/', 'name' => 'Twitter' },
              { 'uid' => 'https://facebook.com/', 'name' => 'Facebook' }
            ]
          }
        end

        before { make_request }

        it 'responds correctly' do
          aggregate_failures do
            expect(last_response.status).to eq(expected_status)
            expect(last_response.content_type).to eq('application/json')
            expect(response_json).to eq(expected_response)
          end
        end
      end
    end

    context 'when q=config is provided' do
      let(:make_request) { get '/?q=config' }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'

      context 'when verification succeeds' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok] }
        let(:response_json) { JSON.parse(last_response.body) }
        let(:expected_response) do
          {
            'media-endpoint' => expected_media_endpoint,
            'syndicate-to' => [
              { 'uid' => 'https://twitter.com/', 'name' => 'Twitter' },
              { 'uid' => 'https://facebook.com/', 'name' => 'Facebook' }
            ],
            'destination' => [
              { 'uid' => 'https://first-site.example.com/', 'name' => 'Site 1' },
              { 'uid' => 'https://second-site.example.com/', 'name' => 'Site 2' },
              { 'uid' => 'https://third-site.example.com/', 'name' => 'Site 3' }
            ]
          }.compact
        end

        before do
          ENV['MEDIA_ENDPOINT'] = expected_media_endpoint

          make_request
        end

        context 'when the media endpoint is not set' do
          let(:expected_media_endpoint) { nil }

          it 'responds correctly' do
            aggregate_failures do
              expect(last_response.status).to eq(expected_status)
              expect(last_response.content_type).to eq('application/json')
              expect(response_json).to eq(expected_response)
            end
          end
        end

        context 'when the media endpoint is set' do
          let(:expected_media_endpoint) { 'http://media.example.com/' }

          it 'responds correctly' do
            aggregate_failures do
              expect(last_response.status).to eq(expected_status)
              expect(last_response.content_type).to eq('application/json')
              expect(response_json).to eq(expected_response)
            end
          end
        end
      end
    end

    context 'when q=source is provided' do
      let(:make_request) { get '/?q=source' }
      it_behaves_like 'a request with missing destinations'

      context 'when a error occurs' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request] }
        let(:expected_error_type) { 'invalid_request' }

        context 'due to the url being missing' do
          let(:expected_error_description) { "'url' must be provided to retrieve 'source'" }

          before { make_request }

          context 'due to not being provided' do
            let(:make_request) { get '/?q=source' }

            it_behaves_like 'an error response'
          end

          context 'due to being empty' do
            let(:make_request) { get '/?q=source&url=' }

            it_behaves_like 'an error response'
          end
        end

        context 'due to the url not matching the supported destinations' do
          let(:make_request) { get "/?q=source&url=#{url}" }
          let(:url) { 'https://totally-real-url.example.com/' }
          let(:post_factory) { instance_double(HoTan::PostFactory) }
          let(:expected_error_description) { 'An unrecognised destination was provided' }

          before do
            allow(HoTan::PostFactory).to receive(:new) { post_factory }
            allow(post_factory).to receive(:from).and_raise(HoTan::PostFactory::UnrecognisedDestinationError)
            make_request
          end

          it_behaves_like 'an error response'
        end

        context 'due to the url not being recognised' do
          let(:make_request) { get "/?q=source&url=#{url}" }
          let(:url) { 'https://totally-real-url.example.com/' }
          let(:post_factory) { instance_double(HoTan::PostFactory) }
          let(:expected_error_description) { "'url' not recognised" }

          before do
            allow(HoTan::PostFactory).to receive(:new) { post_factory }
            allow(post_factory).to receive(:from).and_raise(HoTan::Post::InvalidPathError)
            make_request
          end

          it_behaves_like 'an error response'
        end
      end

      context 'when no error occurs' do
        let(:post_factory) { instance_double(HoTan::PostFactory) }
        let(:existing_post) { double(:post, instance: post_instance) }
        let(:post_instance) { double(:post_instance, data: post_data) }
        let(:post_data) do
          {
            'type' => ['h-entry'],
            'properties' => {
              'content' => ['Some content'],
              'title' => ['A title'],
              'tags' => %w[a b],
              'entry_type' => ['the_type']
            }
          }
        end

        before do
          allow(HoTan::PostFactory).to receive(:new) { post_factory }
          allow(post_factory).to receive(:from) { existing_post }
          make_request
        end

        context 'when no properties are specified' do
          let(:make_request) { get '/?q=source&url=http://example.com/foo' }
          let(:body) { JSON.parse(last_response.body) }
          let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok] }
          let(:expected_data) do
            {
              'type' => ['h-entry'],
              'properties' => {
                'content' => ['Some content'],
                'title' => ['A title'],
                'tags' => %w[a b]
              }
            }
          end

          it 'returns the correct response' do
            aggregate_failures do
              expect(body).to eq(expected_data)
              expect(last_response.status).to eq(expected_status)
              expect(last_response.content_type).to eq('application/json')
            end
          end
        end

        context 'when properties are specified' do
          context 'when only one property is specified' do
            let(:make_request) { get '/?q=source&properties=title&url=http://example.com/foo' }
            let(:body) { JSON.parse(last_response.body) }
            let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok] }
            let(:expected_data) do
              {
                'properties' => {
                  'title' => ['A title']
                }
              }
            end

            it 'returns the correct response' do
              aggregate_failures do
                expect(body).to eq(expected_data)
                expect(last_response.status).to eq(expected_status)
                expect(last_response.content_type).to eq('application/json')
              end
            end
          end

          context 'when more than one property is specified' do
            let(:make_request) { get '/?q=source&properties[]=tags&properties[]=content&url=http://example.com/foo' }
            let(:body) { JSON.parse(last_response.body) }
            let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:ok] }
            let(:expected_data) do
              {
                'properties' => {
                  'content' => ['Some content'],
                  'tags' => %w[a b]
                }
              }
            end

            it 'returns the correct response' do
              aggregate_failures do
                expect(body).to eq(expected_data)
                expect(last_response.status).to eq(expected_status)
                expect(last_response.content_type).to eq('application/json')
              end
            end
          end
        end
      end
    end
  end

  context 'POST' do
    context 'creating a post' do
      let(:create_params) { {} }
      let(:make_request) { post '/', create_params }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'


      context 'attempts to verify with a scope of "create"' do
        before do
          allow(token_verifier).to receive(:verify).and_raise(IndieAuth::TokenVerification::InsufficentScopeError)
          make_request
        end

        it { expect(token_verifier).to have_received(:verify).with('create') }
      end

      context 'when an error occurs' do
        it_behaves_like 'an invalid create request'
      end

      context 'when successful' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:accepted] }
        let(:post_factory) { instance_double(HoTan::PostFactory) }
        let(:created_post) do
          instance_double(HoTan::Post, absolute_url: 'http://example.com/some/post')
        end

        before do
          allow(HoTan::PostFactory).to receive(:new) { post_factory }
          allow(post_factory).to receive(:create) { created_post }

          make_request
        end

        it { expect(last_response.status).to eq(expected_status) }
        it { expect(last_response['Location']).to eq(created_post.absolute_url) }
      end
    end

    context 'updating a post' do
      let(:url) { 'https://example.com/foo/bar' }
      let(:update_params) { { 'action' => 'update', 'add' => { 'foo' => 'bar' } } }
      let(:make_request) { post '/', update_params }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'

      context 'attempts to verify with a scope of "update"' do
        before do
          allow(token_verifier).to receive(:verify).and_raise(IndieAuth::TokenVerification::InsufficentScopeError)
          make_request
        end

        it { expect(token_verifier).to have_received(:verify).with('update') }
      end

      context 'when an error occurs' do
        it_behaves_like 'an invalid update request'
      end

      context 'when successful' do
        let(:post_factory) { instance_double(HoTan::PostFactory) }
        let(:existing_post) do
          instance_double(HoTan::Post, absolute_url: url, updated_url?: updated_url)
        end

        before do
          allow(HoTan::PostFactory).to receive(:new) { post_factory }
          allow(post_factory).to receive(:from) { existing_post }
          allow(existing_post).to receive(:update!)

          make_request
        end

        context 'when the url for the post is updated' do
          let(:updated_url) { true }
          let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:created] }

          it { expect(existing_post).to have_received(:update!).with(update_params) }
          it { expect(last_response.status).to eq(expected_status) }
          it { expect(last_response['Location']).to eq(existing_post.absolute_url) }
        end

        context 'when the url for the post is not updated' do
          let(:updated_url) { false }
          let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:no_content] }

          it { expect(existing_post).to have_received(:update!).with(update_params) }
          it { expect(last_response.status).to eq(expected_status) }
          it { expect(last_response['Location']).to be_nil }
        end
      end
    end

    context 'deleting a post' do
      let(:url) { 'https://example.com/foo/bar' }
      let(:delete_params) { { 'url' => url } }
      let(:make_request) { post '/?action=delete', delete_params }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'

      context 'attempts to verify with a scope of "delete"' do
        before do
          allow(token_verifier).to receive(:verify).and_raise(IndieAuth::TokenVerification::InsufficentScopeError)
          make_request
        end

        it { expect(token_verifier).to have_received(:verify).with('delete') }
      end

      context 'when an error occurs' do
        it_behaves_like 'an invalid delete or undelete request'
      end

      context 'when successful' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:no_content] }
        let(:post_factory) { instance_double(HoTan::PostFactory) }
        let(:created_post) do
          instance_double(HoTan::Post, absolute_url: url)
        end

        before do
          allow(HoTan::PostFactory).to receive(:new) { post_factory }
          allow(post_factory).to receive(:from) { created_post }
          allow(created_post).to receive(:delete!) { true }

          make_request
        end

        it { expect(created_post).to have_received(:delete!) }
        it { expect(last_response.status).to eq(expected_status) }
      end
    end

    context 'undeleting a post' do
      let(:url) { 'https://example.com/foo/bar' }
      let(:undelete_params) { { 'url' => url } }
      let(:make_request) { post '/?action=undelete', undelete_params }

      it_behaves_like 'a request with missing destinations'
      it_behaves_like 'an endpoint requiring verification'

      context 'attempts to verify with a scope of "undelete"' do
        before do
          allow(token_verifier).to receive(:verify).and_raise(IndieAuth::TokenVerification::InsufficentScopeError)
          make_request
        end

        it { expect(token_verifier).to have_received(:verify).with('undelete') }
      end

      context 'when an error occurs' do
        it_behaves_like 'an invalid delete or undelete request'
      end

      context 'when successful' do
        let(:expected_status) { Rack::Utils::SYMBOL_TO_STATUS_CODE[:no_content] }
        let(:post_factory) { instance_double(HoTan::PostFactory) }
        let(:created_post) do
          instance_double(HoTan::Post, absolute_url: url)
        end

        before do
          allow(HoTan::PostFactory).to receive(:new) { post_factory }
          allow(post_factory).to receive(:from) { created_post }
          allow(created_post).to receive(:undelete!) { true }

          make_request
        end

        it { expect(created_post).to have_received(:undelete!) }
        it { expect(last_response.status).to eq(expected_status) }
      end
    end
  end
end

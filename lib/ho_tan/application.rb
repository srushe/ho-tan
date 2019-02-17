# frozen_string_literal: true

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/reloader' if development?
require 'indie_auth/token_verification'
require 'indieweb/post_types'
require 'indieweb/post_types/identifier/bookmark'
require 'indieweb/post_types/identifier/read'
require 'indieweb/post_types/identifier/scrobble'
require_relative 'destinations'
require_relative 'post_factory'

module HoTan
  class Application < Sinatra::Application
    set :public_folder, ::File.dirname(__FILE__) + '/../../static'

    set :syndication_targets, []
    set :destinations, []
    config_file ENV['SYNDICATION_TARGET_CONFIG'] if ENV.key?('SYNDICATION_TARGET_CONFIG')
    config_file ENV['DESTINATION_CONFIG'] if ENV.key?('DESTINATION_CONFIG')

    before do
      halt 503, 'Destinations must be configured' if settings.destinations.empty?
    end

    Indieweb::PostTypes.configure do |config|
      config.insert_identifier(klass: Indieweb::PostTypes::Identifier::Bookmark,
                               before: Indieweb::PostTypes::Identifier::Article)
      config.insert_identifier(klass: Indieweb::PostTypes::Identifier::Read,
                               before: Indieweb::PostTypes::Identifier::Article)
      config.insert_identifier(klass: Indieweb::PostTypes::Identifier::Scrobble,
                               before: Indieweb::PostTypes::Identifier::Article)
    end

    get '/' do
      send_file ::File.join(settings.public_folder, 'index.html') unless params.key?('q')

      verify_token

      content_type :json

      unless %w[config source syndicate-to destination].include?(params['q'])
        send_error(description: "'#{params['q']}' is not a valid value for 'q'")
      end

      return render_source if params['q'] == 'source'

      response = {}
      if params['q'] == 'config'
        response['media-endpoint'] = ENV['MEDIA_ENDPOINT']
      end
      if %w[config syndicate-to].include?(params['q'])
        response['syndicate-to'] = settings.syndication_targets
      end
      if %w[config destination].include?(params['q'])
        response['destination'] = destinations.to_config
      end

      response.compact.to_json
    end

    # Create/Edit post
    post '/' do
      scope = params.fetch('action', 'create')
      verify_token(scope)

      create_post unless params.key?(:action)

      if params.key?(:action)
        begin
          post = post_factory.from(params[:url])
        rescue HoTan::PostFactory::UnrecognisedDestinationError
          send_error(description: 'An unrecognised destination was provided')
        rescue HoTan::Post::DataFile::NotFoundError
          send_error(status: 400, error: 'invalid_request', description: 'Post not found for provided URL')
        end

        case params[:action]
        when 'delete'
          delete_post(post)
        when 'undelete'
          undelete_post(post)
        when 'update'
          update_post(post)
        end
      end
    end

    private

    def verify_token(scope = nil)
      access_token = request.env['HTTP_AUTHORIZATION'] || params['access_token'] || ''
      IndieAuth::TokenVerification.new(access_token).verify(scope)
    rescue IndieAuth::TokenVerification::AccessTokenMissingError
      send_error(status: 401, error: 'unauthorized', description: 'Access token missing or empty')
    rescue IndieAuth::TokenVerification::MissingDomainError
      send_error(status: 400, error: 'invalid_request', description: 'DOMAIN is not specified')
    rescue IndieAuth::TokenVerification::MissingTokenEndpointError
      send_error(status: 400, error: 'invalid_request', description: 'TOKEN_ENDPOINT is not specified')
    rescue IndieAuth::TokenVerification::ForbiddenUserError
      send_error(status: 403, error: 'forbidden', description: 'User does not have permission')
    rescue IndieAuth::TokenVerification::IncorrectMeError
      send_error(status: 401, error: 'insufficient_scope', description: 'The "me" value does not match the expected DOMAIN')
    rescue IndieAuth::TokenVerification::InsufficentScopeError
      send_error(status: 401, error: 'insufficient_scope', description: 'The scope of this token does not meet the requirements for this request')
    end

    def send_error(status: 400, error: 'invalid_request', description:)
      json = {
        error: error,
        error_description: description
      }.to_json

      halt(status, { 'Content-Type' => 'application/json' }, json)
    end

    def destinations
      @destinations ||= HoTan::Destinations.from(settings.destinations)
    end

    def post_factory
      @post_factory ||= HoTan::PostFactory.new(destinations: destinations)
    end

    def render_source
      if params.fetch(:url, '').strip.empty?
        send_error(description: "'url' must be provided to retrieve 'source'")
      end

      post = post_factory.from(params[:url])
      data = post.instance.data

      # Extract selected properties.
      source_data = if params.key?('properties')
                      {
                        'properties' => data['properties'].select do |k, _v|
                                          params['properties'].include?(k)
                                        end
                      }
                    else
                      data.select { |k, _v| %w[properties type].include?(k) }
                    end

      # Remove entry_type from properties, if there.
      source_data['properties'].delete('entry_type')

      source_data.to_json
    rescue HoTan::PostFactory::UnrecognisedDestinationError
      send_error(description: 'An unrecognised destination was provided')
    rescue HoTan::Post::InvalidPathError
      send_error(description: "'url' not recognised")
    end

    def create_post
      post = post_factory.create(params)

      status 202
      headers 'Location' => post.absolute_url
    rescue HoTan::Post::Normalize::InvalidHError
      send_error(description: "'h' must be provided")
    rescue HoTan::Post::Normalize::InvalidTypeError
      send_error(description: 'A type must be provided')
    rescue HoTan::Post::Normalize::InvalidCreateError
      send_error(description: 'No recognisable parameters for entry creation')
    rescue HoTan::PostFactory::UnrecognisedDestinationError
      send_error(description: 'An unrecognised destination was provided')
    rescue HoTan::Post::UnrecognisedTypeError => e
      send_error(description: e.message)
    rescue HoTan::Post::DuplicateCreateError
      send_error(description: 'Failed to create due to an already existing entry')
    end

    def update_post(post)
      post.update!(params)

      if post.updated_url?
        status 201
        headers 'Location' => post.absolute_url
      else
        status 204
      end
    rescue HoTan::Post::InvalidUpdateError
      send_error(description: 'Invalid update parameters provided')
    rescue HoTan::PostFactory::UnrecognisedDestinationError
      send_error(description: 'An unrecognised destination was provided')
    rescue HoTan::Post::UnrecognisedTypeError => e
      send_error(description: e.message)
    end

    def delete_post(post)
      post.delete!
      status 204
    end

    def undelete_post(post)
      post.undelete!
      status 204
    end
  end
end

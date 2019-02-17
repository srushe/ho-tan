# frozen_string_literal: true

require 'dotenv/load'
require 'rack/contrib'
require './lib/ho_tan/application'

# Parse JSON in the body when the content-type is application/json.
use Rack::PostBodyContentTypeParser

run HoTan::Application

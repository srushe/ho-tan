# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "git@github.com:#{repo_name}" }

gem 'sinatra'
gem 'sinatra-contrib'
gem 'dotenv'
gem 'addressable'
gem 'babosa', github: 'norman/babosa'
gem 'rack-contrib'
gem 'indieauth-token-verification'
gem 'indieweb-post_types'
gem 'indieweb-post_types-identifier-bookmark'
gem 'indieweb-post_types-identifier-read'
gem 'indieweb-post_types-identifier-scrobble', github: 'srushe/indieweb-post_types-identifier-scrobble'

group :test, :development do
  gem 'rack-test'
  gem 'rspec'
  gem 'simplecov', require: false
  gem 'timecop'
end

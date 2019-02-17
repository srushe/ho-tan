# frozen_string_literal: true

module HoTan
  class Destination
    attr_reader :uid, :name, :directory, :base_url, :default

    def initialize(data)
      @uid = data['uid']
      @name = data['name']
      @directory = data['directory']
      @base_url = data['base_url']
      @default = !!data['default']
    end

    def default?
      @default == true
    end

    def to_config
      { 'uid' => @uid, 'name' => @name }
    end
  end
end

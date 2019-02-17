# frozen_string_literal: true

require_relative '../../../../lib/ho_tan/post/normalize'
require 'timecop'

RSpec.describe HoTan::Post::Normalize do
  context '#for_create' do
    subject(:normalized_data) { described_class.for_create(data) }

    before { Timecop.freeze(Time.parse('2019-01-07 20:00:00 UTC')) }
    after { Timecop.return }

    let(:expected_data) do
      {
        'type' => ['h-entry'],
        'properties' => {
          'content' => ['hello world'],
          'category' => %w[foo bar],
          'photo' => ['https://photos.example.com/592829482876343254.jpg'],
          'published' => [Time.now.utc.iso8601]
        }
      }
    end

    context 'when the format of the data cannot be determined' do
      let(:data) { {} }

      it { expect { normalized_data }.to raise_error(HoTan::Post::Normalize::InvalidCreateError) }
    end

    context 'when the data comes in a URL-encoded form' do
      let(:data) do
        {
          'h' => h_value,
          'content' => 'hello world',
          'category' => %w[foo bar],
          'photo' => 'https://photos.example.com/592829482876343254.jpg'
        }
      end

      context 'but the "h" value is not set to "entry"' do
        let(:h_value) { 'event' }

        it { expect { normalized_data }.to raise_error(HoTan::Post::Normalize::InvalidHError) }
      end

      context 'and the "h" value is set to "entry"' do
        let(:h_value) { 'entry' }

        it { expect(normalized_data).to eq(expected_data) }
      end
    end

    context 'when the data comes as JSON' do
      let(:data) do
        {
          'type' => [type],
          'properties' => {
            'content' => ['hello world'],
            'category' => %w[foo bar],
            'photo' => ['https://photos.example.com/592829482876343254.jpg']
          }
        }
      end

      context 'but the first "type" value is not set to "h-entry"' do
        let(:type) { 'h-event' }

        it { expect { normalized_data }.to raise_error(HoTan::Post::Normalize::InvalidTypeError) }
      end

      context 'and the first "type" value is set to "h-entry"' do
        let(:type) { 'h-entry' }

        it { expect(normalized_data).to eq(expected_data) }
      end
    end
  end
end

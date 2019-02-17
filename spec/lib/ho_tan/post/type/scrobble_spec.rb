# frozen_string_literal: true

require_relative '../../../../../lib/ho_tan/post/type/scrobble'
require 'timecop'

RSpec.describe HoTan::Post::Type::Scrobble do
  subject(:post) { described_class.new(data) }

  let(:base_data) do
    {
      'properties' => {
        'scrobble-of' => [
          {
            'properties' => {
              'artist' => [artist],
              'title' => [title],
            }
          }
        ],
        'published' => ['2016-02-21T12:50:53-08:00']
      }
    }
  end
  let(:artist) { nil }
  let(:title) { nil }

  describe '.slug' do
    let(:artist) { 'Boards of Canada' }
    let(:title) { 'Triangles & Rhombuses' }

    context 'when an mp-slug entry is provided' do
      let(:data) do
        data = base_data.dup
        data['properties']['mp-slug'] = [mp_slug]
        data
      end

      context 'and is valid' do
        let(:mp_slug) { 'a--valid--slug ' }

        it { expect(post.slug).to eq 'a-valid-slug' }
      end

      context 'and is not valid' do
        let(:expected_slug) { 'boards-of-canada-triangles-rhombuses-125053' }

        context 'as it reduces to a dash' do
          let(:mp_slug) { '  -----  ' }

          it { expect(post.slug).to eq expected_slug }
        end
      end
    end

    context 'when an mp-slug entry is not provided' do
      let(:data) { base_data }
      let(:expected_slug) { 'boards-of-canada-triangles-rhombuses-125053' }

      it { expect(post.slug).to eq expected_slug }

      context 'when the slug source contains a period' do
        let(:artist) { 'Public Service Broadcasting' }
        let(:title) { 'E.V.A.' }
        let(:expected_slug) { 'public-service-broadcasting-eva-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a comma' do
        let(:artist) { 'Underworld' }
        let(:title) { 'Boy, Boy, Boy' }
        let(:expected_slug) { 'underworld-boy-boy-boy-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains an apostrophe' do
        let(:title) { "Ready Let's Go" }
        let(:expected_slug) { 'boards-of-canada-ready-lets-go-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains an ampersand' do
        let(:artist) { 'Burger & Ink (Duo)' }
        let(:title) { 'Twelve Miles High' }
        let(:expected_slug) { 'burger-ink-duo-twelve-miles-high-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a digit' do
        let(:title) { '1969' }
        let(:expected_slug) { 'boards-of-canada-1969-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a bracket' do
        let(:artist) { 'Underworld' }
        let(:title) { 'Push Upstairs (Remastered)' }
        let(:expected_slug) { 'underworld-push-upstairs-remastered-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a forward-slash' do
        let(:artist) { 'Autechre' }
        let(:title) { 'C/Pach' }
        let(:expected_slug) { 'autechre-cpach-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a hash' do
        let(:artist) { 'µ-Ziq' }
        let(:title) { 'Secret Stair #1' }
        let(:expected_slug) { 'μ-ziq-secret-stair-1-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a dollar' do
        let(:artist) { 'Aphex Twin' }
        let(:title) { 'Inkey$' }
        let(:expected_slug) { 'aphex-twin-inkey-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a pound sign' do
        let(:artist) { 'Aphex Twin' }
        let(:title) { 'Girl Boy (£18 Snarerush Mix)' }
        let(:expected_slug) { 'aphex-twin-girl-boy-18-snarerush-mix-125053' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a "special" character' do
        context 'such as "µ"' do
          let(:artist) { 'µ-Ziq' }
          let(:title) { 'Hasty Boom Alert' }
          let(:expected_slug) { 'μ-ziq-hasty-boom-alert-125053' }

          it { expect(post.slug).to eq expected_slug }
        end

        context 'such as "é"' do
          let(:artist) { 'Isolée' }
          let(:title) { 'Beau Mot Plage (Original Version)' }
          let(:expected_slug) { 'isolee-beau-mot-plage-original-version-125053' }

          it { expect(post.slug).to eq expected_slug }
        end
      end
    end
  end
end

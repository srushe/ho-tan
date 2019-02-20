# frozen_string_literal: true

require_relative '../../../../../lib/ho_tan/post/type/read'

RSpec.describe HoTan::Post::Type::Read do
  let(:base_data) do
    {
      'type' => ['h-entry'],
      'properties' => {
        'summary' => ["Finished reading: #{title}, ISBN: 9781408885390"],
        'read-status' => ['finished'],
        'read-of' => [
          {
            'type' => ['h-cite'],
            'properties' => {
              'name' => [title],
              'author' => ['Ben Macintyre'],
              'uid' => ['isbn:9781408885390']
            }
          }
        ],
        'published' => ['2019-02-07T12:34:56Z']
      }
    }
  end

  describe '.path' do
    subject(:instance) { described_class.new(base_data) }

    let(:title) { 'Some title' }

    it { expect(instance.path).to eq('reading/2019/02/07') }
  end

  describe '.slug' do
    subject(:post) { described_class.new(data) }

    let(:title) { 'Agent Zigzag' }

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
        let(:expected_slug) { 'agent-zigzag' }

        context 'as it reduces to a dash' do
          let(:mp_slug) { '  -----  ' }

          it { expect(post.slug).to eq expected_slug }
        end
      end
    end

    context 'when an mp-slug entry is not provided' do
      let(:data) { base_data }
      let(:expected_slug) { 'agent-zigzag' }

      it { expect(post.slug).to eq expected_slug }

      context 'when the slug source contains a period' do
        let(:title) { 'E.V.A.' }
        let(:expected_slug) { 'eva' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a comma' do
        let(:title) { 'Eats, Shoots & Leaves' }
        let(:expected_slug) { 'eats-shoots-leaves' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains an apostrophe' do
        let(:title) { "Ready Let's Go" }
        let(:expected_slug) { 'ready-lets-go' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains an ampersand' do
        let(:title) { 'Eats, Shoots & Leaves' }
        let(:expected_slug) { 'eats-shoots-leaves' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a digit' do
        let(:title) { '1969' }
        let(:expected_slug) { '1969' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a bracket' do
        let(:title) { 'Bill James Baseball Abstract 1985' }
        let(:expected_slug) { 'bill-james-baseball-abstract-1985' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a forward-slash' do
        let(:title) { 'Some/thing or other' }
        let(:expected_slug) { 'something-or-other' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a hash' do
        let(:title) { 'Preacher Book #1' }
        let(:expected_slug) { 'preacher-book-1' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a dollar' do
        let(:title) { 'Football for $1' }
        let(:expected_slug) { 'football-for-1' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a pound sign' do
        let(:title) { 'Football for £1' }
        let(:expected_slug) { 'football-for-1' }

        it { expect(post.slug).to eq expected_slug }
      end

      context 'when the slug source contains a "special" character' do
        context 'such as "é"' do
          let(:title) { 'A book about John Le Carré' }
          let(:expected_slug) { 'a-book-about-john-le-carre' }

          it { expect(post.slug).to eq expected_slug }
        end
      end

      context 'when the slug source contains an apostrophe' do
        let(:title) { 'Operation Mincemeat: The True Spy Story that Changed the Course of World War II' }
        let(:expected_slug) { 'operation-mincemeat' }

        it { expect(post.slug).to eq expected_slug }
      end
    end
  end
end

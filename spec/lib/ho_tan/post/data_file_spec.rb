# frozen_string_literal: true

require_relative '../../../../lib/ho_tan/post/data_file'

RSpec.describe HoTan::Post::DataFile do
  let(:path) { 'a/path/to/a/file.json' }

  context '#new' do
    subject(:data_file) { described_class.new(path) }

    it { expect(data_file.path).to eq(path) }
  end

  context '.read' do
    subject(:data_file) do
      described_class.new(path).read
    end

    let(:json_data) { 'some json' }

    before do
      allow(File).to receive(:exist?) { file_exists }
      allow(File).to receive(:read) { json_data }
      allow(JSON).to receive(:parse)
    end

    context 'when the file exists' do
      let(:file_exists) { true }

      before { data_file }

      it 'attempts to read the data' do
        aggregate_failures do
          expect(File).to have_received(:exist?).with(path)
          expect(File).to have_received(:read).with(path)
          expect(JSON).to have_received(:parse).with(json_data)
        end
      end
    end

    context 'when the file does not exist' do
      let(:file_exists) { false }

      it 'does not attempt to read the data' do
        begin data_file rescue nil end
        aggregate_failures do
          expect(File).to have_received(:exist?).with(path)
          expect(File).not_to have_received(:read)
          expect(JSON).not_to have_received(:parse)
        end
      end

      it { expect { data_file }.to raise_error(HoTan::Post::DataFile::NotFoundError) }
    end
  end

  context '.save' do
    let(:data) do
      {
        'type' => 'h-entry',
        'properties' => {
          'some' => ['data']
        }
      }
    end
    let(:pretty_json) { double(:pretty_json) }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(JSON).to receive(:pretty_generate) { pretty_json }
      allow(File).to receive(:write)

      described_class.new(path).save(data)
    end

    it 'attempts to save the data' do
      aggregate_failures do
        expect(FileUtils).to have_received(:mkdir_p).with('a/path/to/a')
        expect(JSON).to have_received(:pretty_generate).with(data)
        expect(File).to have_received(:write).with(path, pretty_json)
      end
    end
  end

  context '.delete' do
    subject(:data_file) { described_class.new(path) }

    before do
      allow(FileUtils).to receive(:rm)

      data_file.delete!
    end

    it { expect(FileUtils).to have_received(:rm).with(path) }
  end
end

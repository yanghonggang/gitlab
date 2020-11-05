# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Formatters::DependencyList do
  let(:formatter) { described_class.new(project, sha) }
  let(:project) { create(:project) }
  let(:sha) { '4242424242424242' }

  let(:parsed_report) do
    Gitlab::Json.parse!(
      File.read(
        Rails.root.join('ee/spec/fixtures/security_reports/dependency_list/gl-dependency-scanning-report.json')
      )
    )
  end

  describe '#format' do
    let(:package_manager) { 'bundler' }
    let(:file_path) { 'file.path' }
    let(:data) { formatter.format(dependency, package_manager, file_path) }
    let(:blob_path) { "/#{project.full_path}/-/blob/#{sha}/file.path" }

    context 'with secure dependency' do
      context 'with top-level dependency' do
        let(:dependency) { parsed_report['dependency_files'][1]['dependencies'][0] }

        it 'formats the dependency' do
          expect(data[:name]).to eq('async')
          expect(data[:iid]).to eq(1)
          expect(data[:location][:blob_path]).to eq(blob_path)
          expect(data[:location][:path]).to eq('file.path')
          expect(data[:location][:top_level]).to be_truthy
          expect(data[:location][:ancestors]).to be_nil
        end
      end

      context 'with dependency path included' do
        let(:dependency) { parsed_report['dependency_files'][1]['dependencies'][4] }

        it 'formats the dependency' do
          expect(data[:name]).to eq('ms')
          expect(data[:iid]).to eq(5)
          expect(data[:location][:blob_path]).to eq(blob_path)
          expect(data[:location][:path]).to eq('file.path')
          expect(data[:location][:top_level]).to be_falsey
          expect(data[:location][:ancestors][0][:iid]).to eq(3)
        end
      end

      context 'without dependency path' do
        let(:dependency) { parsed_report['dependency_files'][0]['dependencies'][0] }

        it 'formats the dependency' do
          expect(data[:name]).to eq('mini_portile2')
          expect(data[:iid]).to be_nil
          expect(data[:packager]).to eq('Ruby (Bundler)')
          expect(data[:package_manager]).to eq('bundler')
          expect(data[:location][:blob_path]).to eq(blob_path)
          expect(data[:location][:path]).to eq('file.path')
          expect(data[:location][:top_level]).to be_nil
          expect(data[:location][:ancestors]).to be_nil
          expect(data[:version]).to eq('2.2.0')
          expect(data[:vulnerabilities]).to be_empty
          expect(data[:licenses]).to be_empty
        end
      end
    end

    context 'when feature flag for dependency path is off' do
      let(:dependency) { parsed_report['dependency_files'][0]['dependencies'][0] }
      let(:location) { data[:location] }

      before do
        stub_feature_flags(path_to_vulnerable_dependency: false)
      end

      it { expect(location[:top_level]).to be_nil }
      it { expect(location[:ancestors]).to be_nil }
      it { expect(location[:path]).to eq('file.path') }
    end

    context 'with vulnerable dependency' do
      let(:data) { formatter.format(dependency, package_manager, file_path, parsed_report['vulnerabilities'].first) }
      let(:dependency) { parsed_report['dependency_files'][0]['dependencies'][1] }

      it 'merge vulnerabilities data' do
        vulnerabilities = data[:vulnerabilities]

        expect(vulnerabilities.first[:name]).to eq('Vulnerabilities in libxml2 in nokogiri')
        expect(vulnerabilities.first[:severity]).to eq('high')
      end
    end
  end

  describe 'packager' do
    using RSpec::Parameterized::TableSyntax

    where(:packager, :expected) do
      'bundler'  | 'Ruby (Bundler)'
      'yarn'     | 'JavaScript (Yarn)'
      'npm'      | 'JavaScript (npm)'
      'pip'      | 'Python (pip)'
      'maven'    | 'Java (Maven)'
      'composer' | 'PHP (Composer)'
      'conan'    | 'C/C++ (Conan)'
      ''         | ''
    end

    with_them do
      it 'substitutes with right values' do
        expect(formatter.send(:packager, packager)).to eq(expected)
      end
    end
  end
end

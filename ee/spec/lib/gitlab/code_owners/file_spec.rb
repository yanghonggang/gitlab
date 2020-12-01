# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::File do
  include FakeBlobHelpers

  # 'project' is required for the #fake_blob helper
  #
  let(:project) { build(:project) }
  let(:file_content) do
    File.read(Rails.root.join('ee', 'spec', 'fixtures', 'codeowners_example'))
  end

  let(:blob) { fake_blob(path: 'CODEOWNERS', data: file_content) }

  subject(:file) { described_class.new(blob) }

  describe '#parsed_data' do
    def owner_line(pattern)
      file.parsed_data["codeowners"][pattern].owner_line
    end

    context "when CODEOWNERS file contains no sections" do
      it 'parses all the required lines' do
        expected_patterns = [
          '/**/*', '/**/#file_with_pound.rb', '/**/*.rb', '/**/CODEOWNERS', '/**/LICENSE', '/docs/**/*',
          '/docs/*', '/config/**/*', '/**/lib/**/*', '/**/path with spaces/**/*'
        ]

        expect(file.parsed_data["codeowners"].keys)
          .to contain_exactly(*expected_patterns)
      end

      it 'allows usernames and emails' do
        expect(owner_line('/**/LICENSE')).to include('legal', 'janedoe@gitlab.com')
      end
    end

    context "when handling a sectional codeowners file" do
      using RSpec::Parameterized::TableSyntax

      shared_examples_for "creates expected parsed sectional results" do
        it "is a hash sorted by sections without duplicates" do
          data = file.parsed_data

          expect(data.keys.length).to eq(5)
          expect(data.keys).to contain_exactly(
            "codeowners",
            "Documentation",
            "Database",
            "Two Words",
            "Double::Colon"
          )
        end

        codeowners_section_paths = [
          "/**/#file_with_pound.rb", "/**/*", "/**/*.rb", "/**/CODEOWNERS",
          "/**/LICENSE", "/**/lib/**/*", "/**/path with spaces/**/*",
          "/config/**/*", "/docs/*", "/docs/**/*"
        ]

        codeowners_section_owners = [
          "@all-docs", "@config-owner", "@default-codeowner",
          "@legal this does not match janedoe@gitlab.com", "@lib-owner",
          "@multiple @owners\t@tab-separated", "@owner-file-with-pound",
          "@root-docs", "@ruby-owner", "@space-owner"
        ]

        where(:section, :patterns, :owners) do
          "codeowners"    | codeowners_section_paths | codeowners_section_owners
          "Documentation" | ["/**/README.md", "/**/ee/docs", "/**/docs"] | ["@gl-docs"]
          "Database"      | ["/**/README.md", "/**/model/db"] | ["@gl-database"]
          "Two Words"     | ["/**/README.md", "/**/model/db"] | ["@gl-database"]
          "Double::Colon" | ["/**/README.md", "/**/model/db"] | ["@gl-database"]
        end

        with_them do
          it "assigns the correct paths to each section" do
            expect(file.parsed_data[section].keys).to contain_exactly(*patterns)
            expect(file.parsed_data[section].values.detect { |entry| entry.section != section }).to be_nil
          end

          it "assigns the correct owners for each entry" do
            extracted_owners = file.parsed_data[section].values.collect(&:owner_line).uniq
            expect(extracted_owners).to contain_exactly(*owners)
          end
        end
      end

      it "populates a hash with a single default section" do
        data = file.parsed_data

        expect(data.keys.length).to eq(1)
        expect(data.keys).to contain_exactly(::Gitlab::CodeOwners::Entry::DEFAULT_SECTION)
      end

      context "when CODEOWNERS file contains multiple sections" do
        let(:file_content) do
          File.read(Rails.root.join("ee", "spec", "fixtures", "sectional_codeowners_example"))
        end

        it_behaves_like "creates expected parsed sectional results"
      end

      context "when CODEOWNERS file contains multiple sections with mixed-case names" do
        let(:file_content) do
          File.read(Rails.root.join("ee", "spec", "fixtures", "mixed_case_sectional_codeowners_example"))
        end

        it_behaves_like "creates expected parsed sectional results"
      end
    end
  end

  describe '#empty?' do
    subject { file.empty? }

    it { is_expected.to be(false) }

    context 'when there is no content' do
      let(:file_content) { "" }

      it { is_expected.to be(true) }
    end

    context 'when the file is binary' do
      let(:blob) { fake_blob(binary: true) }

      it { is_expected.to be(true) }
    end

    context 'when the file did not exist' do
      let(:blob) { nil }

      it { is_expected.to be(true) }
    end
  end

  describe "#path" do
    context "when the blob exists" do
      it "returns the path to the file" do
        expect(subject.path).to eq(blob.path)
      end
    end

    context "when the blob is nil" do
      let(:blob) { nil }

      it "returns nil" do
        expect(subject.path).to be_nil
      end
    end
  end

  describe '#sections' do
    subject { file.sections }

    context 'when CODEOWNERS file contains sections' do
      let(:file_content) do
        <<~CONTENT
        *.rb @ruby-owner

        [Documentation]
        *.md @gl-docs

        [Test]
        *_spec.rb @gl-test

        [Documentation]
        doc/* @gl-docs
        CONTENT
      end

      it 'returns unique sections' do
        is_expected.to match_array(%w[codeowners Documentation Test])
      end
    end

    context 'when CODEOWNERS file is missing' do
      let(:blob) { nil }

      it 'returns a default section' do
        is_expected.to match_array(['codeowners'])
      end
    end
  end

  describe '#entry_for_path' do
    shared_examples_for "returns expected matches" do
      context 'for a path without matches' do
        let(:file_content) do
          <<~CONTENT
          # Simulating a CODOWNERS without entries
          CONTENT
        end

        it 'returns an empty array for an unmatched path' do
          entry = file.entry_for_path('no_matches')

          expect(entry).to be_a Array
          expect(entry).to be_empty
        end
      end

      it 'matches random files to a pattern' do
        entry = file.entry_for_path('app/assets/something.vue').first

        expect(entry.pattern).to eq('*')
        expect(entry.owner_line).to include('default-codeowner')
      end

      it 'uses the last pattern if multiple patterns match' do
        entry = file.entry_for_path('hello.rb').first

        expect(entry.pattern).to eq('*.rb')
        expect(entry.owner_line).to eq('@ruby-owner')
      end

      it 'returns the usernames for a file matching a pattern with a glob' do
        entry = file.entry_for_path('app/models/repository.rb').first

        expect(entry.owner_line).to eq('@ruby-owner')
      end

      it 'allows specifying multiple users' do
        entry = file.entry_for_path('CODEOWNERS').first

        expect(entry.owner_line).to include('multiple', 'owners', 'tab-separated')
      end

      it 'returns emails and usernames for a matched pattern' do
        entry = file.entry_for_path('LICENSE').first

        expect(entry.owner_line).to include('legal', 'janedoe@gitlab.com')
      end

      it 'allows escaping the pound sign used for comments' do
        entry = file.entry_for_path('examples/#file_with_pound.rb').first

        expect(entry.owner_line).to include('owner-file-with-pound')
      end

      it 'returns the usernames for a file nested in a directory' do
        entry = file.entry_for_path('docs/projects/index.md').first

        expect(entry.owner_line).to include('all-docs')
      end

      it 'returns the usernames for a pattern matched with a glob in a folder' do
        entry = file.entry_for_path('docs/index.md').first

        expect(entry.owner_line).to include('root-docs')
      end

      it 'allows matching files nested anywhere in the repository', :aggregate_failures do
        lib_entry = file.entry_for_path('lib/gitlab/git/repository.rb').first
        other_lib_entry = file.entry_for_path('ee/lib/gitlab/git/repository.rb').first

        expect(lib_entry.owner_line).to include('lib-owner')
        expect(other_lib_entry.owner_line).to include('lib-owner')
      end

      it 'allows allows limiting the matching files to the root of the repository', :aggregate_failures do
        config_entry = file.entry_for_path('config/database.yml').first
        other_config_entry = file.entry_for_path('other/config/database.yml').first

        expect(config_entry.owner_line).to include('config-owner')
        expect(other_config_entry.owner_line).to eq('@default-codeowner')
      end

      it 'correctly matches paths with spaces' do
        entry = file.entry_for_path('path with spaces/docs.md').first

        expect(entry.owner_line).to eq('@space-owner')
      end

      context 'paths with whitespaces and username lookalikes' do
        let(:file_content) do
          'a/weird\ path\ with/\ @username\ /\ and-email@lookalikes.com\ / @user-1 email@gitlab.org @user-2'
        end

        it 'parses correctly' do
          entry = file.entry_for_path('a/weird path with/ @username / and-email@lookalikes.com /test.rb').first

          expect(entry.owner_line).to include('user-1', 'user-2', 'email@gitlab.org')
          expect(entry.owner_line).not_to include('username', 'and-email@lookalikes.com')
        end
      end

      context 'a glob on the root directory' do
        let(:file_content) do
          '/* @user-1 @user-2'
        end

        it 'matches files in the root directory' do
          entry = file.entry_for_path('README.md').first

          expect(entry.owner_line).to include('user-1', 'user-2')
        end

        it 'does not match nested files' do
          entry = file.entry_for_path('nested/path/README.md').first

          expect(entry).to be_nil
        end

        context 'partial matches' do
          let(:file_content) do
            'foo/* @user-1 @user-2'
          end

          it 'does not match a file in a folder that looks the same' do
            entry = file.entry_for_path('fufoo/bar').first

            expect(entry).to be_nil
          end

          it 'matches the file in any folder' do
            expect(file.entry_for_path('baz/foo/bar').first.owner_line).to include('user-1', 'user-2')
            expect(file.entry_for_path('/foo/bar').first.owner_line).to include('user-1', 'user-2')
          end
        end
      end
    end

    context "when CODEOWNERS file contains no sections" do
      it_behaves_like "returns expected matches"
    end

    context "when CODEOWNERS file contains multiple sections" do
      let(:file_content) do
        File.read(Rails.root.join("ee", "spec", "fixtures", "sectional_codeowners_example"))
      end

      it_behaves_like "returns expected matches"
    end
  end
end

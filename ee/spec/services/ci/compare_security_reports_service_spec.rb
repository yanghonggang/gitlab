# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareSecurityReportsService do
  let_it_be(:project) { create(:project, :repository) }
  let(:current_user) { project.owner }

  def collect_ids(collection)
    collection.map { |t| t['identifiers'].first['external_id'] }
  end

  describe '#execute DS' do
    before do
      stub_licensed_features(dependency_scanning: true)
    end

    let(:service) { described_class.new(project, current_user, report_type: 'dependency_scanning') }

    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has dependency scanning reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }

      it 'reports new vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(4)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have dependency scanning reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_report, project: project) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_dependency_scanning_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'populates fields based on current_user' do
        payload = subject[:data]['existing'].first

        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(payload['create_vulnerability_feedback_merge_request_path']).to be_present
        expect(payload['create_vulnerability_feedback_dismissal_path']).to be_present
        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(service.current_user).to eq(current_user)
      end

      it 'reports fixed vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].first['identifiers']).to include(a_hash_including('external_id' => 'CVE-2017-5946'))
      end

      it 'reports existing dependency vulenerabilities' do
        expect(subject[:data]['existing'].count).to eq(3)
      end

      it 'reports fixed dependency scanning vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(1)
        compare_keys = collect_ids(subject[:data]['fixed'])
        expected_keys = %w(06565b64-486d-4326-b906-890d9915804d)
        expect(compare_keys).to match_array(expected_keys)
      end
    end

    context 'when head pipeline has corrupted dependency scanning vulnerability reports' do
      let_it_be(:base_pipeline) { build(:ee_ci_pipeline, :with_corrupted_dependency_scanning_report, project: project) }
      let_it_be(:head_pipeline) { build(:ee_ci_pipeline, :with_corrupted_dependency_scanning_report, project: project) }

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('JSON parsing failed')
      end

      it 'returns status and error message when pipeline is nil' do
        result = service.execute(nil, head_pipeline)

        expect(result[:status]).to eq(:error)
        expect(result[:status_reason]).to include('JSON parsing failed')
      end
    end
  end

  describe '#execute CS' do
    before do
      stub_licensed_features(container_scanning: true)
    end

    let(:service) { described_class.new(project, current_user, report_type: 'container_scanning') }

    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has container scanning reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_report, project: project) }

      it 'reports new, existing and fixed vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(8)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have container scanning reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_report, project: project) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_container_scanning_feature_branch, project: project) }

      it 'populates fields based on current_user' do
        payload = subject[:data]['added'].first
        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(payload['create_vulnerability_feedback_merge_request_path']).to be_present
        expect(payload['create_vulnerability_feedback_dismissal_path']).to be_present
        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(service.current_user).to eq(current_user)
      end

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].first['identifiers']).to include(a_hash_including('external_id' => 'CVE-2017-15650'))
      end

      it 'reports existing container vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(0)
      end

      it 'reports fixed container scanning vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(8)
        compare_keys = collect_ids(subject[:data]['fixed'])
        expected_keys = %w(CVE-2017-16997 CVE-2017-18269 CVE-2018-1000001 CVE-2016-10228 CVE-2010-4052 CVE-2018-18520 CVE-2018-16869 CVE-2018-18311)
        expect(compare_keys).to match_array(expected_keys)
      end
    end
  end

  describe '#execute DAST' do
    before do
      stub_licensed_features(dast: true)
    end

    let(:service) { described_class.new(project, current_user, report_type: 'dast') }

    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has DAST reports containing some vulnerabilities' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_dast_report, project: project) }

      it 'reports the new vulnerabilities, while not changing the counts of existing and fixed vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(20)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have DAST reports containing vulnerabilities' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_dast_report, project: project) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_dast_feature_branch, project: project) }

      it 'populates fields based on current_user' do
        payload = subject[:data]['fixed'].first

        expect(payload).to be_present
        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(payload['create_vulnerability_feedback_merge_request_path']).to be_present
        expect(payload['create_vulnerability_feedback_dismissal_path']).to be_present
        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(service.current_user).to eq(current_user)
      end

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].last['identifiers']).to include(a_hash_including('name' => 'CWE-201'))
      end

      it 'reports existing DAST vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(1)
        expect(subject[:data]['existing'].last['identifiers']).to include(a_hash_including('name' => 'CWE-120'))
      end

      it 'reports fixed DAST vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(19)
        expect(subject[:data]['fixed']).to include(
          a_hash_including(
            {
              'identifiers' => a_collection_including(
                a_hash_including(
                  "name" => "CWE-352"
                )
              )
            })
        )
      end
    end
  end

  describe '#execute SAST' do
    before do
      stub_licensed_features(sast: true)
    end

    let(:service) { described_class.new(project, current_user, report_type: 'sast') }

    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has sast reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }

      it 'reports new vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(33)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have sast reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_sast_feature_branch, project: project) }

      it 'populates fields based on current_user' do
        payload = subject[:data]['existing'].first

        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(payload['create_vulnerability_feedback_merge_request_path']).to be_present
        expect(payload['create_vulnerability_feedback_dismissal_path']).to be_present
        expect(payload['create_vulnerability_feedback_issue_path']).to be_present
        expect(service.current_user).to eq(current_user)
      end

      it 'reports new vulnerability' do
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['added'].first['identifiers']).to include(a_hash_including('name' => 'CWE-120'))
      end

      it 'reports existing sast vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(29)
      end

      it 'reports fixed sast vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(4)
        compare_keys = collect_ids(subject[:data]['fixed'])
        expected_keys = %w(char fopen strcpy char)
        expect(compare_keys - expected_keys).to eq([])
      end
    end
  end

  describe '#execute SECRET DETECTION' do
    before do
      stub_licensed_features(secret_detection: true)
    end

    let(:service) { described_class.new(project, current_user, report_type: 'secret_detection') }

    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has secret_detection reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_secret_detection_report, project: project) }

      it 'reports new vulnerabilities' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['added'].count).to eq(1)
        expect(subject[:data]['existing'].count).to eq(0)
        expect(subject[:data]['fixed'].count).to eq(0)
      end
    end

    context 'when base and head pipelines have secret_detection reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_secret_detection_report, project: project) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_secret_detection_feature_branch, project: project) }

      it 'populates fields based on current_user' do
        payload = subject[:data]['existing'].first
        expect(payload).to be_nil
        expect(service.current_user).to eq(current_user)
      end

      it 'does not report any new vulnerability' do
        expect(subject[:data]['added'].count).to eq(0)
      end

      it 'removes existing secret_detection vulnerabilities' do
        expect(subject[:data]['existing'].count).to eq(0)
      end

      it 'reports fixed secret_detection vulnerabilities' do
        expect(subject[:data]['fixed'].count).to eq(1)
        compare_keys = collect_ids(subject[:data]['fixed'])
        expected_keys = %w(AWS)
        expect(compare_keys).to match_array(expected_keys)
      end
    end
  end
end

# frozen_string_literal: true

FactoryBot.modify do
  factory :project do
    trait :import_hard_failed do
      import_status { :failed }

      after(:create) do |project, evaluator|
        project.import_state.update!(
          retry_count: Gitlab::Mirror::MAX_RETRY + 1,
          last_update_at: Time.now - 1.minute
        )
      end
    end

    trait :mirror do
      mirror { true }
      import_url { generate(:url) }
      mirror_user_id { creator_id }
    end

    trait :random_last_repository_updated_at do
      last_repository_updated_at { rand(1.year).seconds.ago }
    end

    trait :github_imported do
      import_type { 'github' }
    end

    trait :with_vulnerability do
      after(:create) do |project|
        create(:vulnerability, :detected, project: project)
      end
    end

    trait :with_vulnerabilities do
      after(:create) do |project|
        create_list(:vulnerability, 2, :detected, project: project)
      end
    end

    trait :with_compliance_framework do
      association :compliance_framework_setting, factory: :compliance_framework_project_setting
    end

    trait :with_sox_compliance_framework do
      association :compliance_framework_setting, :sox, factory: :compliance_framework_project_setting
    end
  end
end

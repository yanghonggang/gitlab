# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::InstanceSecurityDashboard::AddProject do
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:my_project) { create(:project) }
    let_it_be(:already_added_project) { create(:project) }

    let_it_be(:user) { create(:user, security_dashboard_projects: [already_added_project]) }

    let(:selected_project) { project }

    before do
      my_project.add_developer(user)
      already_added_project.add_developer(user)
    end

    subject { mutation.resolve(id: GitlabSchema.id_from_object(selected_project)) }

    context 'when user is not logged_in' do
      let(:current_user) { nil }

      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is logged_in' do
      let(:current_user) { user }

      context 'when security_dashboard is not enabled' do
        it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when security_dashboard is disabled for my project' do
        context 'when project is not licensed to be added to the security dashboard' do
          let(:selected_project) { my_project }

          it 'does not add project to the security dashboard', :aggregate_failures do
            expect(subject[:project]).to be_nil
            expect(subject[:errors]).to eq([{
              extensions: { code: :NOT_LICENSED },
              message: "Cannot add project #{selected_project.name}. Only projects created under a Gold license are available in Security Dashboards.",
              path: ['addProjectToSecurityDashboard']
            }])
            expect(user.security_dashboard_projects).to include(already_added_project)
          end
        end
      end

      context 'when security_dashboard is enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        context 'when project is available to the user and can be added to the security dashboard' do
          let(:selected_project) { my_project }

          it 'adds project to the security dashboard', :aggregate_failures do
            expect(subject[:project]).to eq(my_project)
            expect(subject[:errors]).to be_empty
            expect(subject[:error_messages]).to be_empty
            expect(user.security_dashboard_projects).to include(my_project)
          end
        end

        context 'when project is not available to the user' do
          let(:selected_project) { project }

          it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable error' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when project is already added to the security dashboard' do
          let(:selected_project) { already_added_project }

          it 'does not add project to the security dashboard', :aggregate_failures do
            expect(subject[:project]).to be_nil
            expect(subject[:errors]).to eq([{
              extensions: { code: :DUPLICATED },
              message: "Cannot add project #{selected_project.name}. The project is already added to your Security Dashboard.",
              path: ['addProjectToSecurityDashboard']
            }])
            expect(user.security_dashboard_projects).to include(already_added_project)
          end
        end
      end
    end
  end
end

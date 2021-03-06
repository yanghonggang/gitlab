import { shallowMount } from '@vue/test-utils';
import { GlDeprecatedButton } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import download from '~/lib/utils/downloader';
import * as urlUtility from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import Header from 'ee/vulnerabilities/components/header.vue';
import StatusDescription from 'ee/vulnerabilities/components/status_description.vue';
import ResolutionAlert from 'ee/vulnerabilities/components/resolution_alert.vue';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import VulnerabilityStateDropdown from 'ee/vulnerabilities/components/vulnerability_state_dropdown.vue';
import VulnerabilitiesEventBus from 'ee/vulnerabilities/components/vulnerabilities_event_bus';
import { FEEDBACK_TYPES, VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';

const vulnerabilityStateEntries = Object.entries(VULNERABILITY_STATE_OBJECTS);
const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');
jest.mock('~/lib/utils/downloader');

describe('Vulnerability Header', () => {
  let wrapper;

  const defaultVulnerability = {
    id: 1,
    created_at: new Date().toISOString(),
    report_type: 'sast',
    state: 'detected',
  };

  const diff = 'some diff to download';

  const getFinding = ({
    shouldShowCreateIssueButton = false,
    shouldShowMergeRequestButton = false,
  }) => {
    return {
      description: 'description',
      identifiers: 'identifiers',
      links: 'links',
      location: 'location',
      name: 'name',
      issue_feedback: shouldShowCreateIssueButton ? null : { issue_iid: 12 },
      remediations: shouldShowMergeRequestButton ? [{ diff }] : null,
      merge_request_feedback: {
        merge_request_path: shouldShowMergeRequestButton ? null : 'some path',
      },
    };
  };

  const dataset = {
    createMrUrl: '/create_mr_url',
    createIssueUrl: '/create_issue_url',
    projectFingerprint: 'abc123',
    pipeline: {
      id: 2,
      created_at: new Date().toISOString(),
      url: 'pipeline_url',
      sourceBranch: 'master',
    },
  };

  const createRandomUser = () => {
    const user = UsersMockHelper.createRandomUser();
    const url = Api.buildUrl(Api.userPath).replace(':id', user.id);
    mockAxios.onGet(url).replyOnce(200, user);

    return user;
  };

  const findGlDeprecatedButton = () => wrapper.find(GlDeprecatedButton);
  const findSplitButton = () => wrapper.find(SplitButton);
  const findBadge = () => wrapper.find({ ref: 'badge' });
  const findResolutionAlert = () => wrapper.find(ResolutionAlert);
  const findStatusDescription = () => wrapper.find(StatusDescription);

  const createWrapper = ({ vulnerability = {}, finding = getFinding({}), props = {} }) => {
    wrapper = shallowMount(Header, {
      propsData: {
        ...dataset,
        ...props,
        initialVulnerability: { ...defaultVulnerability, ...vulnerability },
        finding,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.reset();
    createFlash.mockReset();
  });

  describe('state dropdown', () => {
    beforeEach(() => createWrapper({}));

    it('the vulnerability state dropdown is rendered', () => {
      expect(wrapper.find(VulnerabilityStateDropdown).exists()).toBe(true);
    });

    it('when the vulnerability state dropdown emits a change event, a POST API call is made', () => {
      const dropdown = wrapper.find(VulnerabilityStateDropdown);
      mockAxios.onPost().reply(201);

      dropdown.vm.$emit('change');

      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1); // Check that a POST request was made.
      });
    });

    it('when the vulnerability state dropdown emits a change event, the state badge updates', () => {
      const newState = 'dismiss';
      mockAxios.onPost().reply(201, { state: newState });
      expect(findBadge().text()).not.toBe(newState);

      const dropdown = wrapper.find(VulnerabilityStateDropdown);

      dropdown.vm.$emit('change');

      return waitForPromises().then(() => {
        expect(findBadge().text()).toBe(newState);
      });
    });

    it('when the vulnerability state dropdown emits a change event, the vulnerabilities event bus event is emitted with the proper event', () => {
      const newState = 'dismiss';
      jest.spyOn(VulnerabilitiesEventBus, '$emit');
      mockAxios.onPost().reply(201, { state: newState });
      expect(findBadge().text()).not.toBe(newState);

      const dropdown = wrapper.find(VulnerabilityStateDropdown);

      dropdown.vm.$emit('change');

      return waitForPromises().then(() => {
        expect(VulnerabilitiesEventBus.$emit).toHaveBeenCalledTimes(1);
        expect(VulnerabilitiesEventBus.$emit).toHaveBeenCalledWith('VULNERABILITY_STATE_CHANGE');
      });
    });

    it('when the vulnerability state changes but the API call fails, an error message is displayed', () => {
      const dropdown = wrapper.find(VulnerabilityStateDropdown);
      mockAxios.onPost().reply(400);

      dropdown.vm.$emit('change');

      return waitForPromises().then(() => {
        expect(mockAxios.history.post).toHaveLength(1);
        expect(createFlash).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('split button', () => {
    it('does render the create merge request and issue button as a split button', () => {
      createWrapper({
        finding: getFinding({
          shouldShowCreateIssueButton: true,
          shouldShowMergeRequestButton: true,
        }),
      });
      expect(findSplitButton().exists()).toBe(true);
      const buttons = findSplitButton().props('buttons');
      expect(buttons).toHaveLength(3);
      expect(buttons[0].name).toBe('Resolve with merge request');
      expect(buttons[1].name).toBe('Download patch to resolve');
      expect(buttons[2].name).toBe('Create issue');
    });

    it('does not render the split button if there is only one action', () => {
      createWrapper({ finding: getFinding({ shouldShowCreateIssueButton: true }) });
      expect(findSplitButton().exists()).toBe(false);
    });
  });

  describe('single action button', () => {
    it('does not display if there are no actions', () => {
      createWrapper({});
      expect(findGlDeprecatedButton().exists()).toBe(false);
    });

    describe('create issue', () => {
      beforeEach(() =>
        createWrapper({ finding: getFinding({ shouldShowCreateIssueButton: true }) }),
      );

      it('does display if there is only one action and not an issue already created', () => {
        expect(findGlDeprecatedButton().exists()).toBe(true);
        expect(findGlDeprecatedButton().text()).toBe('Create issue');
      });

      it('calls create issue endpoint on click and redirects to new issue', () => {
        const issueUrl = '/group/project/issues/123';
        const spy = jest.spyOn(urlUtility, 'redirectTo');
        mockAxios.onPost(dataset.createIssueUrl).reply(200, {
          issue_url: issueUrl,
        });
        findGlDeprecatedButton().vm.$emit('click');
        return waitForPromises().then(() => {
          expect(mockAxios.history.post).toHaveLength(1);
          const [postRequest] = mockAxios.history.post;
          expect(postRequest.url).toBe(dataset.createIssueUrl);
          expect(JSON.parse(postRequest.data)).toMatchObject({
            vulnerability_feedback: {
              feedback_type: FEEDBACK_TYPES.ISSUE,
              category: defaultVulnerability.report_type,
              project_fingerprint: dataset.projectFingerprint,
              vulnerability_data: {
                ...defaultVulnerability,
                ...getFinding({ shouldShowCreateIssueButton: true }),
                category: defaultVulnerability.report_type,
                vulnerability_id: defaultVulnerability.id,
              },
            },
          });
          expect(spy).toHaveBeenCalledWith(issueUrl);
        });
      });

      it('shows an error message when issue creation fails', () => {
        mockAxios.onPost(dataset.createIssueUrl).reply(500);
        findGlDeprecatedButton().vm.$emit('click');
        return waitForPromises().then(() => {
          expect(mockAxios.history.post).toHaveLength(1);
          expect(createFlash).toHaveBeenCalledWith(
            'Something went wrong, could not create an issue.',
          );
        });
      });
    });

    describe('create merge request', () => {
      beforeEach(() => {
        createWrapper({
          vulnerability: { state: 'resolved' },
          finding: getFinding({ shouldShowMergeRequestButton: true }),
        });
      });

      it('only renders the create merge request button', () => {
        expect(findGlDeprecatedButton().exists()).toBe(true);
        expect(findGlDeprecatedButton().text()).toBe('Resolve with merge request');
      });

      it('emits createMergeRequest when create merge request button is clicked', () => {
        const mergeRequestPath = '/group/project/merge_request/123';
        const spy = jest.spyOn(urlUtility, 'redirectTo');
        mockAxios.onPost(dataset.createMRUrl).reply(200, {
          merge_request_path: mergeRequestPath,
        });
        findGlDeprecatedButton().vm.$emit('click');
        return waitForPromises().then(() => {
          expect(mockAxios.history.post).toHaveLength(1);
          const [postRequest] = mockAxios.history.post;
          expect(postRequest.url).toBe(dataset.createMrUrl);
          expect(JSON.parse(postRequest.data)).toMatchObject({
            vulnerability_feedback: {
              feedback_type: FEEDBACK_TYPES.MERGE_REQUEST,
              category: defaultVulnerability.report_type,
              project_fingerprint: dataset.projectFingerprint,
              vulnerability_data: {
                ...defaultVulnerability,
                ...getFinding({ shouldShowMergeRequestButton: true }),
                category: defaultVulnerability.report_type,
                state: 'resolved',
              },
            },
          });
          expect(spy).toHaveBeenCalledWith(mergeRequestPath);
        });
      });

      it('shows an error message when merge request creation fails', () => {
        mockAxios.onPost(dataset.createMRUrl).reply(500);
        findGlDeprecatedButton().vm.$emit('click');
        return waitForPromises().then(() => {
          expect(mockAxios.history.post).toHaveLength(1);
          expect(createFlash).toHaveBeenCalledWith(
            'There was an error creating the merge request. Please try again.',
          );
        });
      });
    });

    describe('can download patch', () => {
      beforeEach(() => {
        createWrapper({
          finding: getFinding({ shouldShowMergeRequestButton: true }),
          props: { createMrUrl: '' },
        });
      });

      it('only renders the download patch button', () => {
        expect(findGlDeprecatedButton().exists()).toBe(true);
        expect(findGlDeprecatedButton().text()).toBe('Download patch to resolve');
      });

      it('emits downloadPatch when download patch button is clicked', () => {
        const glDeprecatedButton = findGlDeprecatedButton();
        glDeprecatedButton.vm.$emit('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(download).toHaveBeenCalledWith({ fileData: diff, fileName: `remediation.patch` });
        });
      });
    });
  });

  describe('state badge', () => {
    test.each(vulnerabilityStateEntries)(
      'the vulnerability state badge has the correct style for the %s state',
      (state, stateObject) => {
        createWrapper({ vulnerability: { state } });

        expect(findBadge().classes()).toContain(`status-box-${stateObject.statusBoxStyle}`);
        expect(findBadge().text()).toBe(state);
      },
    );
  });

  describe('status description', () => {
    it('the status description is rendered and passed the correct data', () => {
      const user = createRandomUser();
      const vulnerability = {
        ...defaultVulnerability,
        ...{ state: 'confirmed', confirmed_by_id: user.id },
      };

      createWrapper({ vulnerability });

      return waitForPromises().then(() => {
        expect(findStatusDescription().exists()).toBe(true);
        expect(findStatusDescription().props()).toEqual({
          vulnerability,
          pipeline: dataset.pipeline,
          user,
          isLoadingVulnerability: wrapper.vm.isLoadingVulnerability,
          isLoadingUser: wrapper.vm.isLoadingUser,
        });
      });
    });
  });

  describe('when the vulnerability is no longer detected on the default branch', () => {
    const branchName = 'master';

    beforeEach(() => {
      createWrapper({
        vulnerability: {
          resolved_on_default_branch: true,
          project_default_branch: branchName,
        },
      });
    });

    it('should show the resolution alert component', () => {
      const alert = findResolutionAlert();

      expect(alert.exists()).toBe(true);
    });

    it('should pass down the default branch name', () => {
      const alert = findResolutionAlert();

      expect(alert.props().defaultBranchName).toEqual(branchName);
    });

    describe('when the vulnerability is already resolved', () => {
      beforeEach(() => {
        createWrapper({
          vulnerability: {
            resolved_on_default_branch: true,
            state: 'resolved',
          },
        });
      });

      it('should not show the resolution alert component', () => {
        const alert = findResolutionAlert();

        expect(alert.exists()).toBe(false);
      });
    });
  });

  describe('vulnerability user watcher', () => {
    it.each(vulnerabilityStateEntries)(
      `loads the correct user for the vulnerability state "%s"`,
      state => {
        const user = createRandomUser();
        createWrapper({ vulnerability: { state, [`${state}_by_id`]: user.id } });

        return waitForPromises().then(() => {
          expect(mockAxios.history.get).toHaveLength(1);
          expect(findStatusDescription().props('user')).toEqual(user);
        });
      },
    );

    it('does not load a user if there is no user ID', () => {
      createWrapper({ vulnerability: { state: 'detected' } });

      return waitForPromises().then(() => {
        expect(mockAxios.history.get).toHaveLength(0);
        expect(findStatusDescription().props('user')).toBeUndefined();
      });
    });

    it('will show an error when the user cannot be loaded', () => {
      createWrapper({ vulnerability: { state: 'confirmed', confirmed_by_id: 1 } });

      mockAxios.onGet().replyOnce(500);

      return waitForPromises().then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(mockAxios.history.get).toHaveLength(1);
      });
    });

    it('will set the isLoadingUser property correctly when the user is loading and finished loading', () => {
      const user = createRandomUser();
      createWrapper({ vulnerability: { state: 'confirmed', confirmed_by_id: user.id } });

      expect(findStatusDescription().props('isLoadingUser')).toBe(true);

      return waitForPromises().then(() => {
        expect(mockAxios.history.get).toHaveLength(1);
        expect(findStatusDescription().props('isLoadingUser')).toBe(false);
      });
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import Api from 'ee/api';
import VulnerabilityFooter from 'ee/vulnerabilities/components/footer.vue';
import HistoryEntry from 'ee/vulnerabilities/components/history_entry.vue';
import RelatedIssues from 'ee/vulnerabilities/components/related_issues.vue';
import StatusDescription from 'ee/vulnerabilities/components/status_description.vue';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import initUserPopovers from '~/user_popovers';

const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');
jest.mock('~/user_popovers');

describe('Vulnerability Footer', () => {
  let wrapper;

  const vulnerability = {
    id: 1,
    discussions_url: '/discussions',
    notes_url: '/notes',
    project: {
      full_path: '/root/security-reports',
      full_name: 'Administrator / Security Reports',
    },
    can_modify_related_issues: true,
    related_issues_help_path: 'help/path',
    has_mr: false,
    pipeline: {},
  };

  const createWrapper = (properties = {}) => {
    wrapper = shallowMount(VulnerabilityFooter, {
      propsData: { vulnerability: { ...vulnerability, ...properties } },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.reset();
  });

  describe('fetching discussions', () => {
    it('calls the discussion url on if fetchDiscussions is called by the root', async () => {
      createWrapper();
      jest.spyOn(axios, 'get');
      wrapper.vm.fetchDiscussions();

      await axios.waitForAll();

      expect(axios.get).toHaveBeenCalledTimes(1);
    });
  });

  describe('solution card', () => {
    it('does show solution card when there is one', () => {
      const properties = { remediations: [{ diff: [{}] }], solution: 'some solution' };
      createWrapper(properties);

      expect(wrapper.find(SolutionCard).exists()).toBe(true);
      expect(wrapper.find(SolutionCard).props()).toEqual({
        solution: properties.solution,
        remediation: properties.remediations[0],
        hasDownload: true,
        hasMr: vulnerability.has_mr,
        isStandaloneVulnerability: true,
      });
    });

    it('does not show solution card when there is not one', () => {
      createWrapper();
      expect(wrapper.find(SolutionCard).exists()).toBe(false);
    });
  });

  describe('merge request note', () => {
    const mergeRequestNote = () => wrapper.find(MergeRequestNote);

    it('does not show merge request note when a merge request does not exist for the vulnerability', () => {
      createWrapper();
      expect(mergeRequestNote().exists()).toBe(false);
    });

    it('shows merge request note when a merge request exists for the vulnerability', () => {
      // The object itself does not matter, we just want to make sure it's passed to the issue note.
      const mergeRequestFeedback = {};

      createWrapper({ merge_request_feedback: mergeRequestFeedback });
      expect(mergeRequestNote().exists()).toBe(true);
      expect(mergeRequestNote().props('feedback')).toBe(mergeRequestFeedback);
    });
  });

  describe('state history', () => {
    const discussionUrl = vulnerability.discussions_url;

    const historyList = () => wrapper.find({ ref: 'historyList' });
    const historyEntries = () => wrapper.findAll(HistoryEntry);

    it('does not render the history list if there are no history items', () => {
      mockAxios.onGet(discussionUrl).replyOnce(200, []);
      createWrapper();
      expect(historyList().exists()).toBe(false);
    });

    it('renders the history list if there are history items', () => {
      // The shape of this object doesn't matter for this test, we just need to verify that it's passed to the history
      // entry.
      const historyItems = [{ id: 1, note: 'some note' }, { id: 2, note: 'another note' }];
      mockAxios.onGet(discussionUrl).replyOnce(200, historyItems, { date: Date.now() });
      createWrapper();

      return axios.waitForAll().then(() => {
        expect(historyList().exists()).toBe(true);
        expect(historyEntries()).toHaveLength(2);
        const entry1 = historyEntries().at(0);
        const entry2 = historyEntries().at(1);
        expect(entry1.props('discussion')).toEqual(historyItems[0]);
        expect(entry2.props('discussion')).toEqual(historyItems[1]);
      });
    });

    it('calls initUserPopovers when a new history item is retrieved', () => {
      const historyItems = [{ id: 1, note: 'some note' }];
      mockAxios.onGet(discussionUrl).replyOnce(200, historyItems, { date: Date.now() });

      expect(initUserPopovers).not.toHaveBeenCalled();
      createWrapper();

      return axios.waitForAll().then(() => {
        expect(initUserPopovers).toHaveBeenCalled();
      });
    });

    it('shows an error the history list could not be retrieved', () => {
      mockAxios.onGet(discussionUrl).replyOnce(500);
      createWrapper();

      return axios.waitForAll().then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
      });
    });

    describe('new notes polling', () => {
      jest.useFakeTimers();

      const getDiscussion = (entries, index) => entries.at(index).props('discussion');
      const createNotesRequest = (...notes) =>
        mockAxios
          .onGet(vulnerability.notes_url)
          .replyOnce(200, { notes, last_fetched_at: Date.now() });

      // Following #217184 the vulnerability polling uses an initial timeout
      // which we need to run and then wait for the subsequent request.
      const startTimeoutsAndAwaitRequests = async () => {
        expect(setTimeout).toHaveBeenCalledTimes(1);
        jest.runAllTimers();

        return axios.waitForAll();
      };

      beforeEach(() => {
        const historyItems = [
          { id: 1, notes: [{ id: 100, note: 'some note', discussion_id: 1 }] },
          { id: 2, notes: [{ id: 200, note: 'another note', discussion_id: 2 }] },
        ];
        mockAxios.onGet(discussionUrl).replyOnce(200, historyItems, { date: Date.now() });
        createWrapper();
      });

      it('updates an existing note if it already exists', () => {
        const note = { id: 100, note: 'updated note', discussion_id: 1 };
        createNotesRequest(note);

        return axios.waitForAll().then(async () => {
          await startTimeoutsAndAwaitRequests();

          const entries = historyEntries();
          expect(entries).toHaveLength(2);
          const discussion = getDiscussion(entries, 0);
          expect(discussion.notes.length).toBe(1);
          expect(discussion.notes[0].note).toBe('updated note');
        });
      });

      it('adds a new note to an existing discussion if the note does not exist', () => {
        const note = { id: 101, note: 'new note', discussion_id: 1 };
        createNotesRequest(note);

        return axios.waitForAll().then(async () => {
          await startTimeoutsAndAwaitRequests();

          const entries = historyEntries();
          expect(entries).toHaveLength(2);
          const discussion = getDiscussion(entries, 0);
          expect(discussion.notes.length).toBe(2);
          expect(discussion.notes[1].note).toBe('new note');
        });
      });

      it('creates a new discussion with a new note if the discussion does not exist', () => {
        const note = { id: 300, note: 'new note on a new discussion', discussion_id: 3 };
        createNotesRequest(note);

        return axios.waitForAll().then(async () => {
          await startTimeoutsAndAwaitRequests();

          const entries = historyEntries();
          expect(entries).toHaveLength(3);
          const discussion = getDiscussion(entries, 2);
          expect(discussion.notes.length).toBe(1);
          expect(discussion.notes[0].note).toBe('new note on a new discussion');
        });
      });

      it('calls initUserPopovers when a new note is retrieved', () => {
        expect(initUserPopovers).not.toHaveBeenCalled();
        const note = { id: 300, note: 'new note on a new discussion', discussion_id: 3 };
        createNotesRequest(note);

        return axios.waitForAll().then(() => {
          expect(initUserPopovers).toHaveBeenCalled();
        });
      });

      it('shows an error if the notes poll fails', () => {
        mockAxios.onGet(vulnerability.notes_url).replyOnce(500);

        return axios.waitForAll().then(async () => {
          await startTimeoutsAndAwaitRequests();

          expect(historyEntries()).toHaveLength(2);
          expect(mockAxios.history.get).toHaveLength(2);
          expect(createFlash).toHaveBeenCalled();
        });
      });

      it('emits the vulnerability-state-change event when the system note is new', async () => {
        const handler = jest.fn();
        wrapper.vm.$on('vulnerability-state-change', handler);

        const note = { system: true, id: 1, discussion_id: 3 };
        createNotesRequest(note);

        await axios.waitForAll();

        await startTimeoutsAndAwaitRequests();

        expect(handler).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('related issues', () => {
    const relatedIssues = () => wrapper.find(RelatedIssues);

    it('has the correct props', () => {
      const endpoint = Api.buildUrl(Api.vulnerabilityIssueLinksPath).replace(
        ':id',
        vulnerability.id,
      );
      createWrapper();

      expect(relatedIssues().exists()).toBe(true);
      expect(relatedIssues().props()).toMatchObject({
        endpoint,
        canModifyRelatedIssues: vulnerability.can_modify_related_issues,
        projectPath: vulnerability.project.full_path,
        helpPath: vulnerability.related_issues_help_path,
      });
    });
  });

  describe('detection note', () => {
    const detectionNote = () => wrapper.find('[data-testid="detection-note"]');
    const statusDescription = () => wrapper.find(StatusDescription);
    const vulnerabilityStates = Object.keys(VULNERABILITY_STATES);

    it.each(vulnerabilityStates)(`shows detection note when vulnerability state is '%s'`, state => {
      createWrapper({ state });

      expect(detectionNote().exists()).toBe(true);
      expect(statusDescription().props('vulnerability')).toEqual({
        state: 'detected',
        pipeline: vulnerability.pipeline,
      });
    });
  });
});

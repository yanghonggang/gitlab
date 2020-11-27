import { GlLink, GlSprintf } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import MergeImmediatelyConfirmationDialog from 'ee/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue';
import MergeTrainHelperText from 'ee/vue_merge_request_widget/components/merge_train_helper_text.vue';
import { MERGE_DISABLED_TEXT_UNAPPROVED } from 'ee/vue_merge_request_widget/mixins/ready_to_merge';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import {
  MWPS_MERGE_STRATEGY,
  MT_MERGE_STRATEGY,
  MTWPS_MERGE_STRATEGY,
} from '~/vue_merge_request_widget/constants';
import {
  MERGE_DISABLED_TEXT,
  PIPELINE_MUST_SUCCEED_CONFLICT_TEXT,
} from '~/vue_merge_request_widget/mixins/ready_to_merge';

describe('ReadyToMerge', () => {
  let wrapper;
  let vm;

  const service = {
    merge: () => {},
    poll: () => {},
  };

  const activePipeline = {
    id: 1,
    path: 'path/to/pipeline',
    active: true,
  };

  const mr = {
    isPipelineActive: false,
    pipeline: { id: 1, path: 'path/to/pipeline' },
    isPipelineFailed: false,
    isPipelinePassing: false,
    isMergeAllowed: true,
    onlyAllowMergeIfPipelineSucceeds: false,
    ffOnlyEnabled: false,
    hasCI: false,
    ciStatus: null,
    sha: '12345678',
    squash: false,
    squashIsEnabledByDefault: false,
    squashIsReadonly: false,
    squashIsSelected: false,
    commitMessage: 'This is the commit message',
    squashCommitMessage: 'This is the squash commit message',
    commitMessageWithDescription: 'This is the commit message description',
    shouldRemoveSourceBranch: true,
    canRemoveSourceBranch: false,
    targetBranch: 'master',
    preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY,
    availableAutoMergeStrategies: [MWPS_MERGE_STRATEGY],
    mergeImmediatelyDocsPath: 'path/to/merge/immediately/docs',
    mergeTrainWhenPipelineSucceedsDocsPath: '/merge-train/docs',
    mergeTrainsCount: 0,
  };

  const factory = (mrUpdates = {}, shallow = true) => {
    const func = shallow ? shallowMount : mount;
    wrapper = func(ReadyToMerge, {
      propsData: {
        mr: { ...mr, ...mrUpdates },
        service,
      },
      stubs: {
        MergeImmediatelyConfirmationDialog,
        MergeTrainHelperText,
        GlSprintf,
        GlLink,
      },
    });

    ({ vm } = wrapper);
  };

  const findResolveItemsMessage = () => wrapper.find(GlSprintf);
  const findPipelineConflictMessage = () =>
    wrapper.find('[data-testid="pipeline-succeed-conflict"]');
  const findMergeButton = () => wrapper.find('.qa-merge-button');
  const findMergeButtonDropdown = () => wrapper.find('.js-merge-moment');
  const findMergeImmediatelyButton = () => wrapper.find('.js-merge-immediately-button');
  const findMergeTrainHelperText = () => wrapper.find(MergeTrainHelperText);
  const findMergeTrainPipelineLink = () =>
    findMergeTrainHelperText().find('[data-testid="pipeline-link"]');
  const findMergeTrainDocumentationLink = () =>
    findMergeTrainHelperText().find('[data-testid="documentation-link"]');

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('computed', () => {
    describe('mergeButtonText', () => {
      it('should return "Merge" when no auto merge strategies are available', () => {
        factory({ availableAutoMergeStrategies: [] });

        expect(vm.mergeButtonText).toEqual('Merge');
      });

      it('should return "Merge in progress"', () => {
        factory();
        wrapper.setData({ isMergingImmediately: true });

        expect(vm.mergeButtonText).toEqual('Merge in progress');
      });

      it('should return "Merge when pipeline succeeds" when the MWPS auto merge strategy is available', () => {
        factory({
          preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY,
        });

        expect(vm.mergeButtonText).toEqual('Merge when pipeline succeeds');
      });

      it('should return "Start merge train" when the merge train auto merge stategy is available and there is no existing merge train', () => {
        factory({
          preferredAutoMergeStrategy: MT_MERGE_STRATEGY,
          mergeTrainsCount: 0,
        });

        expect(vm.mergeButtonText).toEqual('Start merge train');
      });

      it('should return "Add to merge train" when the merge train auto merge stategy is available and a merge train already exists', () => {
        factory({
          preferredAutoMergeStrategy: MT_MERGE_STRATEGY,
          mergeTrainsCount: 1,
        });

        expect(vm.mergeButtonText).toEqual('Add to merge train');
      });

      it('should return "Start merge train when pipeline succeeds" when the MTWPS auto merge strategy is available and there is no existing merge train', () => {
        factory({
          preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 0,
        });

        expect(vm.mergeButtonText).toEqual('Start merge train when pipeline succeeds');
      });

      it('should return "Add to merge train when pipeline succeeds" when the MTWPS auto merge strategy is available and a merge train already exists', () => {
        factory({
          preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 1,
        });

        expect(vm.mergeButtonText).toEqual('Add to merge train when pipeline succeeds');
      });
    });

    describe('autoMergeText', () => {
      it('should return Merge when pipeline succeeds', () => {
        factory({ preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY });

        expect(vm.autoMergeText).toEqual('Merge when pipeline succeeds');
      });

      it('should return Start merge train when pipeline succeeds', () => {
        factory({
          preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 0,
        });

        expect(vm.autoMergeText).toEqual('Start merge train when pipeline succeeds');
      });

      it('should return Add to merge train when pipeline succeeds', () => {
        factory({
          preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
          mergeTrainsCount: 1,
        });

        expect(vm.autoMergeText).toEqual('Add to merge train when pipeline succeeds');
      });
    });

    describe('isMergeImmediatelyDangerous', () => {
      it('should return false if the preferred auto merge strategy is not merge train-related', () => {
        factory({ preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY });

        expect(vm.isMergeImmediatelyDangerous).toBe(false);
      });

      it('should return true if the preferred auto merge strategy is merge trains', () => {
        factory({ preferredAutoMergeStrategy: MT_MERGE_STRATEGY });

        expect(vm.isMergeImmediatelyDangerous).toBe(true);
      });

      it('should return true if the preferred auto merge strategy is merge trains when pipeline succeeds', () => {
        factory({ preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY });

        expect(vm.isMergeImmediatelyDangerous).toBe(true);
      });
    });
  });

  describe('shouldRenderMergeTrainHelperText', () => {
    it('should render the helper text if MTWPS is available and the user has not yet pressed the MTWPS button', () => {
      factory({
        onlyAllowMergeIfPipelineSucceeds: true,
        preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
        autoMergeEnabled: false,
      });

      expect(findMergeTrainHelperText().exists()).toBe(true);
    });
  });

  describe('merge train helper text', () => {
    it('does not render the merge train helper text if the MTWPS strategy is not available', () => {
      factory({
        availableAutoMergeStrategies: [MT_MERGE_STRATEGY],
        pipeline: activePipeline,
      });

      expect(findMergeTrainHelperText().exists()).toBe(false);
    });

    it('renders the correct merge train helper text when there is an existing merge train', () => {
      factory({
        onlyAllowMergeIfPipelineSucceeds: true,
        preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
        autoMergeEnabled: false,
        mergeTrainsCount: 2,
        pipeline: activePipeline,
      });

      expect(findMergeTrainHelperText().text()).toContain(
        `This action will add the merge request to the merge train when pipeline #${activePipeline.id} succeeds.`,
      );
    });

    it('renders the correct merge train helper text when there is no existing merge train', () => {
      factory({
        onlyAllowMergeIfPipelineSucceeds: true,
        preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
        autoMergeEnabled: false,
        mergeTrainsCount: 0,
        pipeline: activePipeline,
      });

      expect(findMergeTrainHelperText().text()).toContain(
        `This action will start a merge train when pipeline #${activePipeline.id} succeeds.`,
      );
    });

    it('renders the correct pipeline link inside the message', () => {
      factory({
        onlyAllowMergeIfPipelineSucceeds: true,
        preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
        autoMergeEnabled: false,
        mergeTrainsCount: 0,
        pipeline: activePipeline,
      });

      const pipelineLink = findMergeTrainPipelineLink();

      expect(pipelineLink.text()).toContain(activePipeline.id);
      expect(pipelineLink.attributes('href')).toBe(activePipeline.path);
    });

    it('renders the documentation link inside the message', () => {
      factory({
        onlyAllowMergeIfPipelineSucceeds: true,
        preferredAutoMergeStrategy: MTWPS_MERGE_STRATEGY,
        autoMergeEnabled: false,
        mergeTrainsCount: 0,
        pipeline: activePipeline,
      });

      const pipelineLink = findMergeTrainDocumentationLink();

      expect(pipelineLink.text()).toContain('More information');
      expect(pipelineLink.attributes('href')).toBe(mr.mergeTrainWhenPipelineSucceedsDocsPath);
    });
  });

  describe('shouldShowMergeImmediatelyDropdown', () => {
    it('should return false if no pipeline is active', () => {
      factory({
        isPipelineActive: false,
        onlyAllowMergeIfPipelineSucceeds: false,
      });

      expect(vm.shouldShowMergeImmediatelyDropdown).toBe(false);
    });

    it('should return false if "Pipelines must succeed" is enabled for the current project', () => {
      factory({
        isPipelineActive: true,
        onlyAllowMergeIfPipelineSucceeds: true,
      });

      expect(vm.shouldShowMergeImmediatelyDropdown).toBe(false);
    });

    it('should return true if the MR\'s pipeline is active and "Pipelines must succeed" is not enabled for the current project', () => {
      factory({
        isPipelineActive: true,
        onlyAllowMergeIfPipelineSucceeds: false,
      });

      expect(vm.shouldShowMergeImmediatelyDropdown).toBe(true);
    });

    it('should return true when the merge train auto merge stategy is available ', () => {
      factory({
        preferredAutoMergeStrategy: MT_MERGE_STRATEGY,
        isPipelineActive: false,
        onlyAllowMergeIfPipelineSucceeds: true,
      });

      expect(vm.shouldShowMergeImmediatelyDropdown).toBe(true);
    });
  });

  describe('merge immediately warning dialog', () => {
    let dialog;

    const clickMergeImmediately = () => {
      dialog = wrapper.find(MergeImmediatelyConfirmationDialog);

      expect(dialog.exists()).toBe(true);
      dialog.vm.show = jest.fn();
      vm.handleMergeButtonClick = jest.fn();
      findMergeButtonDropdown().trigger('click');
      return wrapper.vm.$nextTick().then(() => {
        findMergeImmediatelyButton().trigger('click');
        return wrapper.vm.$nextTick();
      });
    };

    it('should show a warning dialog asking for confirmation if the user is trying to skip the merge train', () => {
      factory({ preferredAutoMergeStrategy: MT_MERGE_STRATEGY }, false);
      return clickMergeImmediately().then(() => {
        expect(dialog.vm.show).toHaveBeenCalled();
        expect(vm.handleMergeButtonClick).not.toHaveBeenCalled();
      });
    });

    it('should perform the merge when the user confirms their intent to merge immediately', () => {
      factory({ preferredAutoMergeStrategy: MT_MERGE_STRATEGY }, false);
      return clickMergeImmediately()
        .then(() => {
          dialog.vm.$emit('mergeImmediately');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(vm.handleMergeButtonClick).toHaveBeenCalled();
        });
    });

    it('should not ask for confirmation in non-merge train scenarios', () => {
      factory(
        {
          isPipelineActive: true,
          onlyAllowMergeIfPipelineSucceeds: false,
        },
        false,
      );
      return clickMergeImmediately().then(() => {
        expect(dialog.vm.show).not.toHaveBeenCalled();
        expect(vm.handleMergeButtonClick).toHaveBeenCalled();
      });
    });
  });

  describe('cannot merge', () => {
    describe('when isMergeAllowed=false', () => {
      beforeEach(() => {
        factory({
          isMergeAllowed: false,
          availableAutoMergeStrategies: [],
        });
      });

      it('should show cannot merge text', () => {
        expect(findResolveItemsMessage().text()).toBe(MERGE_DISABLED_TEXT);
      });

      it('should show disabled merge button', () => {
        const button = findMergeButton();

        expect(button.exists()).toBe(true);
        expect(button.attributes('disabled')).toBe('true');
      });
    });
  });

  describe('when needs approval', () => {
    beforeEach(() => {
      factory({
        isMergeAllowed: false,
        availableAutoMergeStrategies: [],
        hasApprovalsAvailable: true,
        isApproved: false,
      });
    });

    it('should show approvals needed text', () => {
      expect(findResolveItemsMessage().text()).toBe(MERGE_DISABLED_TEXT_UNAPPROVED);
    });
  });

  describe('when no CI service are found and enforce `Pipeline must succeed`', () => {
    beforeEach(() => {
      factory({
        isMergeAllowed: false,
        availableAutoMergeStrategies: [],
        hasCI: false,
        onlyAllowMergeIfPipelineSucceeds: true,
      });
    });

    it('should show a custom message that explains the conflict', () => {
      expect(findPipelineConflictMessage().text()).toBe(PIPELINE_MUST_SUCCEED_CONFLICT_TEXT);
    });
  });
});

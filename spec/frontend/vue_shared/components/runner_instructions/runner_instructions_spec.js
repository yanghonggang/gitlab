import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';
import getRunnerPlatforms from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_platforms.query.graphql';
import getRunnerSetupInstructions from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_setup.query.graphql';

import { mockGraphqlRunnerPlatforms, mockGraphqlInstructions } from './mock_data';

const projectPath = 'gitlab-org/gitlab';
const localVue = createLocalVue();
localVue.use(VueApollo);

describe('RunnerInstructions component', () => {
  let wrapper;
  let fakeApollo;

  const findModalButton = () => wrapper.find('[data-testid="show-modal-button"]');
  const findPlatformButtons = () => wrapper.findAll('[data-testid="platform-button"]');
  const findArchitectureDropdownItems = () =>
    wrapper.findAll('[data-testid="architecture-dropdown-item"]');
  const findBinaryInstructionsSection = () => wrapper.find('[data-testid="binary-instructions"]');
  const findRunnerInstructionsSection = () => wrapper.find('[data-testid="runner-instructions"]');

  beforeEach(() => {
    const requestHandlers = [
      [getRunnerPlatforms, jest.fn().mockResolvedValue(mockGraphqlRunnerPlatforms)],
      [getRunnerSetupInstructions, jest.fn().mockResolvedValue(mockGraphqlInstructions)],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    wrapper = shallowMount(RunnerInstructions, {
      provide: {
        projectPath,
      },
      localVue,
      apolloProvider: fakeApollo,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should show the "Show Runner installation instructions" button', () => {
    const button = findModalButton();

    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('Show Runner installation instructions');
  });

  it('should contain a number of platforms buttons', () => {
    const buttons = findPlatformButtons();

    expect(buttons).toHaveLength(mockGraphqlRunnerPlatforms.data.runnerPlatforms.nodes.length);
  });

  it('should contain a number of dropdown items for the architecture options', () => {
    const platformButton = findPlatformButtons().at(0);
    platformButton.vm.$emit('click');

    return wrapper.vm.$nextTick(() => {
      const dropdownItems = findArchitectureDropdownItems();

      expect(dropdownItems).toHaveLength(
        mockGraphqlRunnerPlatforms.data.runnerPlatforms.nodes[0].architectures.nodes.length,
      );
    });
  });

  it('should display the binary installation instructions for a selected architecture', async () => {
    const platformButton = findPlatformButtons().at(0);
    platformButton.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const dropdownItem = findArchitectureDropdownItems().at(0);
    dropdownItem.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const runner = findBinaryInstructionsSection();

    expect(runner.text()).toEqual(
      expect.stringContaining('sudo chmod +x /usr/local/bin/gitlab-runner'),
    );
    expect(runner.text()).toEqual(
      expect.stringContaining(
        `sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash`,
      ),
    );
    expect(runner.text()).toEqual(
      expect.stringContaining(
        'sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner',
      ),
    );
    expect(runner.text()).toEqual(expect.stringContaining('sudo gitlab-runner start'));
  });

  it('should display the runner register instructions for a selected architecture', async () => {
    const platformButton = findPlatformButtons().at(0);
    platformButton.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const dropdownItem = findArchitectureDropdownItems().at(0);
    dropdownItem.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const runner = findRunnerInstructionsSection();

    expect(runner.text()).toEqual(
      expect.stringContaining(mockGraphqlInstructions.data.runnerSetup.registerInstructions),
    );
  });
});

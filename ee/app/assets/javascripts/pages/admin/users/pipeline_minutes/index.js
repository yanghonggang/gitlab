import Vue from 'vue';
import ResetButton from './reset_button.vue';

export function pipelineMinutes() {
  const el = document.getElementById('pipeline-minutes-vue');

  if (el) {
    const { resetMinutesPath } = el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      provide: {
        resetMinutesPath,
      },
      render(createElement) {
        return createElement(ResetButton);
      },
    });
  }
}
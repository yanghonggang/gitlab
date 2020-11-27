import Vue from 'vue';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import createStore from 'ee/vue_shared/license_compliance/store/index';
import ProtectedEnvironmentCreate from 'ee/protected_environments/protected_environment_create';
import ProtectedEnvironmentEditList from 'ee/protected_environments/protected_environment_edit_list';
import showToast from '~/vue_shared/plugins/global_toast';
import '~/pages/projects/settings/ci_cd/show/index';

const el = document.getElementById('js-managed-licenses');
const toasts = document.querySelectorAll('.js-toast-message');

if (el?.dataset?.apiUrl) {
  const store = createStore();
  store.dispatch('licenseManagement/setIsAdmin', Boolean(el.dataset.apiUrl));
  store.dispatch('licenseManagement/setAPISettings', { apiUrlManageLicenses: el.dataset.apiUrl });
  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    render(createElement) {
      return createElement(LicenseManagement, {
        props: {
          ...el.dataset,
        },
      });
    },
  });
}

toasts.forEach(toast => showToast(toast.dataset.message));

// eslint-disable-next-line no-new
new ProtectedEnvironmentCreate();

// eslint-disable-next-line no-new
new ProtectedEnvironmentEditList();

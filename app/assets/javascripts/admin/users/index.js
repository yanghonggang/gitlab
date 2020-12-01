import Vue from 'vue';
import AdminUsersApp from './components/admin_users_app.vue';

export default function() {
  const el = document.querySelector('#js-admin-users-app');

  if (!el) return false;

  const { users, currentPage, totalPages, paths } = el.dataset;

  return new Vue({
    el,
    render: createElement =>
      createElement(AdminUsersApp, {
        props: {
          users: JSON.parse(users),
          currentPage: parseInt(currentPage, 10),
          totalPages: parseInt(totalPages, 10),
          paths: JSON.parse(paths),
        },
      }),
  });
}

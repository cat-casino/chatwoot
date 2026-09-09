import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/priority-groups'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'priority_groups_wrapper',
          meta: {
            permissions: ['administrator'],
          },
          redirect: to => {
            return { name: 'priority_groups_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'priority_groups_list',
          meta: {
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};

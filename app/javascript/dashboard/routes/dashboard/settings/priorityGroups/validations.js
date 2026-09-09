import { required } from '@vuelidate/validators';

export const getPriorityGroupNameErrorMessage = validation => {
  if (!validation.name.$error) return '';
  if (!validation.name.required) {
    return 'PRIORITY_GROUP_MGMT.FORM.NAME.REQUIRED_ERROR';
  }
  return '';
};

export default {
  name: {
    required,
  },
};

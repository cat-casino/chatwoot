<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import validations, { getPriorityGroupNameErrorMessage } from './validations';

import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  selectedPriorityGroup: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();

const name = ref(props.selectedPriorityGroup.name);

const v$ = useVuelidate({ name: validations.name }, { name });

const uiFlags = computed(() => getters['priorityGroups/getUIFlags'].value);

const pageTitle = computed(
  () =>
    `${t('PRIORITY_GROUP_MGMT.EDIT.TITLE')} - ${props.selectedPriorityGroup.name}`
);

const nameErrorMessage = computed(() =>
  t(getPriorityGroupNameErrorMessage(v$.value))
);

const onClose = () => {
  emit('close');
};

const editPriorityGroup = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    await store.dispatch('priorityGroups/update', {
      id: props.selectedPriorityGroup.id,
      name: name.value,
    });
    useAlert(t('PRIORITY_GROUP_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    onClose();
  } catch (error) {
    const errorMessage =
      error.message || t('PRIORITY_GROUP_MGMT.EDIT.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <form class="flex flex-wrap mx-0" @submit.prevent="editPriorityGroup">
      <woot-input
        v-model="name"
        :class="{ error: v$.name.$error }"
        class="w-full"
        :label="t('PRIORITY_GROUP_MGMT.FORM.NAME.LABEL')"
        :placeholder="t('PRIORITY_GROUP_MGMT.FORM.NAME.PLACEHOLDER')"
        :error="nameErrorMessage"
        @input="v$.name.$touch"
        @blur="v$.name.$touch"
      />

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="t('PRIORITY_GROUP_MGMT.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :label="t('PRIORITY_GROUP_MGMT.FORM.EDIT')"
          :disabled="v$.name.$invalid || uiFlags.isUpdating"
          :is-loading="uiFlags.isUpdating"
        />
      </div>
    </form>
  </div>
</template>

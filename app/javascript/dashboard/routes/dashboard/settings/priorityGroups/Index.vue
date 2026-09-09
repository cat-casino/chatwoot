<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { picoSearch } from '@chatwoot/pico-search';

import AddPriorityGroup from './AddPriorityGroup.vue';
import EditPriorityGroup from './EditPriorityGroup.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedPriorityGroup = ref({});
const searchQuery = ref('');

const records = computed(
  () => getters['priorityGroups/allPriorityGroups'].value
);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name']);
});

const uiFlags = computed(() => getters['priorityGroups/getUIFlags'].value);

const deleteMessage = computed(() => ` ${selectedPriorityGroup.value.name}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = priorityGroup => {
  showEditPopup.value = true;
  selectedPriorityGroup.value = priorityGroup;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = priorityGroup => {
  showDeleteConfirmationPopup.value = true;
  selectedPriorityGroup.value = priorityGroup;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deletePriorityGroup = async id => {
  try {
    await store.dispatch('priorityGroups/delete', id);
    useAlert(t('PRIORITY_GROUP_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('PRIORITY_GROUP_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedPriorityGroup.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedPriorityGroup.value.id] = true;
  closeDeletePopup();
  deletePriorityGroup(selectedPriorityGroup.value.id);
};

const tableHeaders = computed(() => {
  return [
    t('PRIORITY_GROUP_MGMT.LIST.TABLE_HEADER.NAME'),
    t('PRIORITY_GROUP_MGMT.LIST.TABLE_HEADER.ACTION'),
  ];
});

onBeforeMount(() => {
  store.dispatch('priorityGroups/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('PRIORITY_GROUP_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('PRIORITY_GROUP_MGMT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('PRIORITY_GROUP_MGMT.HEADER')"
        :description="$t('PRIORITY_GROUP_MGMT.DESCRIPTION')"
        :search-placeholder="$t('PRIORITY_GROUP_MGMT.SEARCH_PLACEHOLDER')"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('PRIORITY_GROUP_MGMT.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('PRIORITY_GROUP_MGMT.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="tableHeaders"
        :items="filteredRecords"
        :no-data-message="
          searchQuery
            ? $t('PRIORITY_GROUP_MGMT.NO_RESULTS')
            : $t('PRIORITY_GROUP_MGMT.LIST.404')
        "
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="priorityGroup in items"
            :key="priorityGroup.id"
            :item="priorityGroup"
          >
            <template #default>
              <BaseTableCell>
                <span class="text-body-main text-n-slate-12">
                  {{ priorityGroup.name }}
                </span>
              </BaseTableCell>

              <BaseTableCell align="end">
                <div class="flex gap-3 justify-end flex-shrink-0">
                  <Button
                    v-tooltip.top="$t('PRIORITY_GROUP_MGMT.FORM.EDIT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    :is-loading="loading[priorityGroup.id]"
                    @click="openEditPopup(priorityGroup)"
                  />
                  <Button
                    v-tooltip.top="$t('PRIORITY_GROUP_MGMT.FORM.DELETE')"
                    icon="i-woot-bin"
                    slate
                    sm
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    :is-loading="loading[priorityGroup.id]"
                    @click="openDeletePopup(priorityGroup)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddPriorityGroup @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditPriorityGroup
        :selected-priority-group="selectedPriorityGroup"
        @close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('PRIORITY_GROUP_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('PRIORITY_GROUP_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('PRIORITY_GROUP_MGMT.DELETE.CONFIRM.YES')"
      :reject-text="$t('PRIORITY_GROUP_MGMT.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>

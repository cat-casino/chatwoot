// import * as types from '../mutation-types';
import PriorityGroupsAPI from '../../api/priorityGroups';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
  getPriorityGroup: $state => id => $state.records[Number(id)] || null,
  allPriorityGroups: $state => Object.values($state.records),
};

export const actions = {
  async get({ commit }) {
    commit('SET_PRIORITY_GROUPS_UI_FLAG', { isFetching: true });

    try {
      const response = await PriorityGroupsAPI.index();

      commit('SET_PRIORITY_GROUPS', { data: response.data });
      commit('SET_PRIORITY_GROUPS_UI_FLAG', {
        isFetching: false,
        isError: false,
      });
    } catch (error) {
      commit('SET_PRIORITY_GROUPS_UI_FLAG', {
        isFetching: false,
        isError: true,
      });
    }
  },

  async create({ commit }, priorityGroupObj) {
    commit('SET_PRIORITY_GROUPS_UI_FLAG', { isCreating: true });
    try {
      const response = await PriorityGroupsAPI.create(priorityGroupObj);
      commit('ADD_PRIORITY_GROUP', response.data);
      return response.data;
    } catch (error) {
      const errorMessage = error?.response?.data?.message || error.message;
      throw new Error(errorMessage);
    } finally {
      commit('SET_PRIORITY_GROUPS_UI_FLAG', { isCreating: false });
    }
  },

  async update({ commit }, { id, ...updateObj }) {
    commit('SET_PRIORITY_GROUPS_UI_FLAG', { isUpdating: true });
    try {
      const response = await PriorityGroupsAPI.update(id, updateObj);
      commit('SET_PRIORITY_GROUP', { id, data: response.data });
      return response.data;
    } catch (error) {
      const errorMessage = error?.response?.data?.message || error.message;
      throw new Error(errorMessage);
    } finally {
      commit('SET_PRIORITY_GROUPS_UI_FLAG', { isUpdating: false });
    }
  },

  async delete({ commit }, id) {
    commit('SET_PRIORITY_GROUPS_UI_FLAG', { isDeleting: true });
    try {
      await PriorityGroupsAPI.delete(id);
      commit('DELETE_PRIORITY_GROUP', id);
    } catch (error) {
      const errorMessage = error?.response?.data?.message || error.message;
      throw new Error(errorMessage);
    } finally {
      commit('SET_PRIORITY_GROUPS_UI_FLAG', { isDeleting: false });
    }
  },

  setPriorityGroup({ commit }, { id, data }) {
    commit('SET_PRIORITY_GROUP', { id, data });
  },
};

export const mutations = {
  SET_PRIORITY_GROUPS_UI_FLAG($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  SET_PRIORITY_GROUPS($state, { data }) {
    const records = {};
    data.forEach(group => {
      records[group.id] = group;
    });
    $state.records = records;
  },

  ADD_PRIORITY_GROUP($state, data) {
    $state.records = { ...$state.records, [data.id]: data };
  },

  SET_PRIORITY_GROUP($state, { id, data }) {
    $state.records = { ...$state.records, [id]: data };
  },

  DELETE_PRIORITY_GROUP($state, id) {
    const records = { ...$state.records };
    delete records[id];
    $state.records = records;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};

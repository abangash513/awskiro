// FIXED VERSION - Stable references, no infinite loops
import React, { createContext, useContext, useState, useCallback, useRef } from 'react';

const FilterContext = createContext(null);

const DEFAULT_FILTERS = {
  cloudProvider: null,
  accountName: null,
  businessUnit: null,
  timeRange: 30,
};

function loadFiltersFromStorage() {
  try {
    const saved = localStorage.getItem('cloudoptima_filters');
    if (saved) {
      return { ...DEFAULT_FILTERS, ...JSON.parse(saved) };
    }
  } catch (e) {
    console.warn('[FilterContext] Failed to load filters from localStorage:', e);
  }
  return DEFAULT_FILTERS;
}

export function FilterProvider({ children }) {
  const [filters, setFiltersState] = useState(loadFiltersFromStorage);

  // Keep a ref always in sync with current filters
  // This allows callbacks to read current values without being in dependencies
  const filtersRef = useRef(filters);
  filtersRef.current = filters;

  const setFilters = useCallback((updater) => {
    setFiltersState((prev) => {
      const next = typeof updater === 'function' ? updater(prev) : { ...prev, ...updater };
      try {
        localStorage.setItem('cloudoptima_filters', JSON.stringify(next));
      } catch (e) {
        console.warn('[FilterContext] Failed to save filters:', e);
      }
      return next;
    });
  }, []);

  const setCloudProvider = useCallback((value) => {
    setFilters((prev) => ({ ...prev, cloudProvider: value }));
  }, [setFilters]);

  const setAccountName = useCallback((value) => {
    setFilters((prev) => ({ ...prev, accountName: value }));
  }, [setFilters]);

  const setBusinessUnit = useCallback((value) => {
    setFilters((prev) => ({ ...prev, businessUnit: value }));
  }, [setFilters]);

  const setTimeRange = useCallback((value) => {
    setFilters((prev) => ({ ...prev, timeRange: value }));
  }, [setFilters]);

  const resetFilters = useCallback(() => {
    setFilters(DEFAULT_FILTERS);
  }, [setFilters]);

  // KEY FIX: getApiParams reads from the ref, so it never needs to be
  // re-created and never causes dependency loop issues.
  // It always returns fresh values because filtersRef.current is always current.
  const getApiParams = useCallback(() => {
    const f = filtersRef.current;
    const params = {};
    if (f.cloudProvider) params.cloud_provider = f.cloudProvider;
    if (f.accountName) params.account_name = f.accountName;
    if (f.businessUnit) params.business_unit = f.businessUnit;

    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(endDate.getDate() - (f.timeRange || 30));

    params.start_date = startDate.toISOString().split('T')[0];
    params.end_date = endDate.toISOString().split('T')[0];

    return params;
  }, []); // Empty deps - stable forever, reads fresh values via ref

  const value = {
    filters,
    setFilters,
    setCloudProvider,
    setAccountName,
    setBusinessUnit,
    setTimeRange,
    resetFilters,
    getApiParams,
  };

  return (
    <FilterContext.Provider value={value}>
      {children}
    </FilterContext.Provider>
  );
}

export function useFilters() {
  const context = useContext(FilterContext);
  if (!context) {
    throw new Error('useFilters must be used within a FilterProvider');
  }
  return context;
}

export default FilterContext;

// FIXED VERSION - Clean filter buttons with no extra re-renders
import React from 'react';
import { useFilters } from '../../contexts/FilterContext';

const TIME_RANGES = [
  { label: '7d', value: 7 },
  { label: '30d', value: 30 },
  { label: '60d', value: 60 },
  { label: '90d', value: 90 },
];

function GlobalFilters() {
  const {
    filters,
    setCloudProvider,
    setAccountName,
    setTimeRange,
    resetFilters,
  } = useFilters();

  return (
    <div className="flex flex-wrap items-center gap-3 p-4 bg-white rounded-lg shadow-sm border border-gray-200">
      {/* Time Range Buttons */}
      <div className="flex items-center gap-1">
        <span className="text-xs text-gray-500 font-medium mr-1">Period:</span>
        {TIME_RANGES.map(({ label, value }) => (
          <button
            key={value}
            onClick={() => setTimeRange(value)}
            className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
              filters.timeRange === value
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Cloud Provider Filter */}
      <div className="flex items-center gap-1">
        <span className="text-xs text-gray-500 font-medium mr-1">Cloud:</span>
        {[
          { label: 'All', value: null },
          { label: 'AWS', value: 'aws' },
          { label: 'Azure', value: 'azure' },
        ].map(({ label, value }) => (
          <button
            key={label}
            onClick={() => setCloudProvider(value)}
            className={`px-3 py-1.5 rounded text-sm font-medium transition-colors ${
              filters.cloudProvider === value
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Reset Button */}
      <button
        onClick={resetFilters}
        className="ml-auto px-3 py-1.5 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded transition-colors"
      >
        Reset filters
      </button>
    </div>
  );
}

export default GlobalFilters;

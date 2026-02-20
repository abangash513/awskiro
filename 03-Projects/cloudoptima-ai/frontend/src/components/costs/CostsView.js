import React, { useState, useEffect } from "react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, Cell,
} from "recharts";
import { DollarSign } from "lucide-react";
import { api } from "../../services/api";
import { useFilters } from "../../contexts/FilterContext";
import GlobalFilters from "../common/GlobalFilters";

const COLORS = ["#3b82f6", "#8b5cf6", "#06b6d4", "#10b981", "#f59e0b", "#ef4444", "#ec4899", "#6366f1"];

export default function CostsView() {
  const [view, setView] = useState("service"); // service | resource_group
  const [trend, setTrend] = useState([]);
  const [breakdown, setBreakdown] = useState([]);
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  
  // Use global filter context
  const { filters } = useFilters();
  
  // Destructure primitive values - these are stable
  const { cloudProvider, accountName, businessUnit, timeRange } = filters;

  useEffect(() => {
    console.log('[CostsView] Starting data fetch...');
    console.log('[CostsView] Filters:', { cloudProvider, accountName, businessUnit, timeRange });
    setLoading(true);
    
    // Build API params directly
    const params = {};
    if (cloudProvider) params.cloud_provider = cloudProvider;
    if (accountName) params.account_name = accountName;
    if (businessUnit) params.business_unit = businessUnit;
    
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(endDate.getDate() - timeRange);
    
    params.start_date = startDate.toISOString().split('T')[0];
    params.end_date = endDate.toISOString().split('T')[0];
    
    console.log('[CostsView] API params:', params);
    
    Promise.all([
      api.getCostSummary(params),
      api.getCostTrend(params),
      view === "service" ? api.getCostByService(params) : api.getCostByResourceGroup(params),
    ])
      .then(([s, t, b]) => { 
        console.log('[CostsView] Data received:', { summary: s, trend: t, breakdown: b });
        // Map API response to component format
        setSummary({
          total_billed_cost: s.total_cost || 0,
          total_effective_cost: s.total_cost || 0,
          cost_change_percent: 0
        });
        setTrend(t.map(item => ({
          date: item.date,
          billed_cost: item.cost || 0
        })));
        setBreakdown(b.map(item => ({
          value: item.service || item.resource_group || 'Unknown',
          billed_cost: item.cost || 0
        })));
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [view, cloudProvider, accountName, businessUnit, timeRange]);

  if (loading) {
    return <div className="animate-pulse space-y-6"><div className="h-64 bg-gray-200 rounded-xl" /></div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Cost Explorer</h1>
          <p className="text-sm text-gray-500 mt-0.5">Analyze spend by service, resource group, and tag</p>
        </div>
        <div className="flex gap-2">
          <GlobalFilters showTimeRange={true} showAccount={true} />
          <div className="w-px bg-gray-200 mx-1" />
          {["service", "resource_group"].map((v) => (
            <button key={v} onClick={() => setView(v)}
              className={`px-4 py-1.5 text-xs rounded-lg font-medium transition-colors ${
                view === v ? "bg-blue-600 text-white" : "bg-white text-gray-600 border border-gray-200 hover:bg-gray-50"
              }`}>
              {v === "service" ? "By Service" : "By Resource Group"}
            </button>
          ))}
        </div>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <p className="text-sm text-gray-500">Total Billed</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">${summary.total_billed_cost.toLocaleString()}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <p className="text-sm text-gray-500">Effective Cost</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">${summary.total_effective_cost.toLocaleString()}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <p className="text-sm text-gray-500">Period Change</p>
            <p className={`text-2xl font-bold mt-1 ${summary.cost_change_percent > 0 ? "text-red-500" : "text-green-600"}`}>
              {summary.cost_change_percent !== null ? `${summary.cost_change_percent > 0 ? "+" : ""}${summary.cost_change_percent}%` : "N/A"}
            </p>
          </div>
        </div>
      )}

      {/* Cost Trend */}
      <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">Daily Cost Trend</h3>
        <ResponsiveContainer width="100%" height={300}>
          <AreaChart data={trend}>
            <defs>
              <linearGradient id="trendGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.15} />
                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(d) => new Date(d).toLocaleDateString("en-US", { month: "short", day: "numeric" })} />
            <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `$${v.toLocaleString()}`} />
            <Tooltip formatter={(v) => [`$${v.toLocaleString()}`, "Cost"]} />
            <Area type="monotone" dataKey="billed_cost" stroke="#3b82f6" strokeWidth={2} fill="url(#trendGrad)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Breakdown */}
      <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">
          Cost by {view === "service" ? "Service" : "Resource Group"}
        </h3>
        <ResponsiveContainer width="100%" height={400}>
          <BarChart data={breakdown} layout="vertical" margin={{ left: 120 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis type="number" tick={{ fontSize: 11 }} tickFormatter={(v) => `$${v.toLocaleString()}`} />
            <YAxis type="category" dataKey="value" tick={{ fontSize: 11 }} width={110} />
            <Tooltip formatter={(v) => `$${v.toLocaleString()}`} />
            <Bar dataKey="billed_cost" radius={[0, 4, 4, 0]}>
              {breakdown.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

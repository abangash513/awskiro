import React, { useState, useEffect } from "react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, BarChart, Bar,
} from "recharts";
import {
  TrendingUp, TrendingDown, DollarSign, Brain, Lightbulb, AlertTriangle
} from "lucide-react";
import { api } from "../../services/api";
import { useFilters } from "../../contexts/FilterContext";
import GlobalFilters from "../common/GlobalFilters";

const COLORS = ["#3b82f6", "#8b5cf6", "#06b6d4", "#10b981", "#f59e0b", "#ef4444", "#ec4899", "#6366f1"];

function MetricCard({ title, value, change, icon: Icon, iconColor = "text-blue-500", prefix = "$" }) {
  const isPositive = change > 0;
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-gray-500 font-medium">{title}</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">
            {prefix}{typeof value === "number" ? value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 }) : value}
          </p>
          {change !== null && change !== undefined && (
            <div className={`flex items-center gap-1 mt-1 text-sm ${isPositive ? "text-red-500" : "text-green-500"}`}>
              {isPositive ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
              <span>{Math.abs(change)}% vs prior period</span>
            </div>
          )}
        </div>
        <div className={`p-2 rounded-lg bg-gray-50 ${iconColor}`}>
          <Icon size={20} />
        </div>
      </div>
    </div>
  );
}

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  
  // Use global filter context
  const { filters } = useFilters();
  
  // Destructure primitive values - these are stable
  const { cloudProvider, accountName, businessUnit, timeRange } = filters;

  useEffect(() => {
    console.log('[Dashboard] Starting data fetch...');
    console.log('[Dashboard] Filters:', { cloudProvider, accountName, businessUnit, timeRange });
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
    
    console.log('[Dashboard] API params:', params);
    
    // POC: Fetch data from available endpoints
    Promise.all([
      api.getCostSummary(params),
      api.getCostTrend(params),
      api.getRecommendationSummary(),
      api.getRecommendations({ ...params, limit: 50 })
    ])
      .then(([costSummary, costTrend, recSummary, recommendations]) => {
        console.log('[Dashboard] Data received:', { costSummary, costTrend, recSummary, recommendations });
        
        // Filter recommendations by cloud if needed
        const filteredRecs = cloudProvider 
          ? recommendations.filter(r => {
              const subId = r.subscription_id;
              if (cloudProvider === 'aws') return subId.startsWith('aws-');
              if (cloudProvider === 'azure') return !subId.startsWith('aws-') && !subId.startsWith('gcp-') && !subId.startsWith('oci-');
              if (cloudProvider === 'gcp') return subId.startsWith('gcp-');
              if (cloudProvider === 'oci') return subId.startsWith('oci-');
              return true;
            })
          : recommendations;

        const dashboardData = {
          cost_summary: {
            total_billed_cost: costSummary.total_cost || 0,
            total_effective_cost: costSummary.total_cost || 0,
            cost_change_percent: 0
          },
          cost_trend: costTrend.map(item => ({
            date: item.date,
            billed_cost: item.cost
          })),
          top_services: costSummary.top_services?.map(svc => ({
            value: svc.service,
            billed_cost: svc.cost
          })) || [],
          recommendation_summary: {
            total_monthly_savings: filteredRecs.reduce((sum, r) => sum + r.estimated_monthly_savings, 0),
            total_open: filteredRecs.length
          },
          top_resources: filteredRecs.slice(0, 5).map(rec => ({
            name: rec.title,
            service: rec.category,
            cost: rec.estimated_monthly_savings
          })),
          ai_summary: null,
          alerts: []
        };
        console.log('[Dashboard] Setting data:', dashboardData);
        setData(dashboardData);
      })
      .catch(err => {
        console.error('[Dashboard] Error fetching data:', err);
        setData(null);
      })
      .finally(() => setLoading(false));
  }, [cloudProvider, accountName, businessUnit, timeRange]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-white rounded-xl border border-gray-200 p-5 h-28 animate-pulse">
              <div className="h-3 bg-gray-200 rounded w-24 mb-3" />
              <div className="h-6 bg-gray-200 rounded w-32" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="text-center py-20">
        <Brain size={48} className="mx-auto text-gray-300 mb-4" />
        <h2 className="text-lg font-semibold text-gray-700">No data yet</h2>
        <p className="text-gray-500 text-sm mt-1">Connect an Azure subscription to start tracking costs.</p>
      </div>
    );
  }

  const { cost_summary, cost_trend, top_services, recommendation_summary, ai_summary, alerts } = data;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-sm text-gray-500 mt-0.5">Cloud cost overview — last {filters.timeRange} days</p>
        </div>
        <GlobalFilters showTimeRange={true} showAccount={true} />
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Spend" value={cost_summary.total_billed_cost}
          change={cost_summary.cost_change_percent} icon={DollarSign} iconColor="text-blue-500"
        />
        <MetricCard
          title="Effective Cost" value={cost_summary.total_effective_cost}
          change={null} icon={DollarSign} iconColor="text-green-500"
        />
        <MetricCard
          title="Potential Savings" value={recommendation_summary.total_monthly_savings}
          change={null} icon={Lightbulb} iconColor="text-amber-500" prefix="$"
        />
        {ai_summary && (
          <MetricCard
            title="AI Workload Cost" value={ai_summary.total_ai_cost}
            change={ai_summary.total_ai_cost_change_percent} icon={Brain} iconColor="text-purple-500"
          />
        )}
        {!ai_summary && (
          <MetricCard
            title="Open Recommendations" value={recommendation_summary.total_open}
            change={null} icon={AlertTriangle} iconColor="text-orange-500" prefix=""
          />
        )}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Cost Trend */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">Cost Trend</h3>
          <ResponsiveContainer width="100%" height={280}>
            <AreaChart data={cost_trend}>
              <defs>
                <linearGradient id="costGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(d) => new Date(d).toLocaleDateString("en-US", { month: "short", day: "numeric" })} />
              <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `$${v.toLocaleString()}`} />
              <Tooltip formatter={(v) => [`$${v.toLocaleString()}`, "Cost"]} labelFormatter={(d) => new Date(d).toLocaleDateString()} />
              <Area type="monotone" dataKey="billed_cost" stroke="#3b82f6" strokeWidth={2} fill="url(#costGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Service Breakdown */}
        <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">Top Services</h3>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={top_services} dataKey="billed_cost" nameKey="value" cx="50%" cy="50%" innerRadius={50} outerRadius={80} paddingAngle={2}>
                {top_services.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Pie>
              <Tooltip formatter={(v) => `$${v.toLocaleString()}`} />
            </PieChart>
          </ResponsiveContainer>
          <div className="space-y-2 mt-2">
            {top_services.slice(0, 5).map((svc, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: COLORS[i % COLORS.length] }} />
                  <span className="text-gray-600 truncate max-w-[140px]">{svc.value}</span>
                </div>
                <span className="text-gray-900 font-medium">${svc.billed_cost.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recommendations + Alerts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Recommendations */}
        <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-semibold text-gray-700">Top Recommendations</h3>
            <span className="text-xs text-gray-400">{recommendation_summary.total_open} open</span>
          </div>
          {data.top_resources?.length > 0 ? (
            <div className="space-y-3">
              {data.top_resources.slice(0, 5).map((res, i) => (
                <div key={i} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                  <div>
                    <p className="text-sm font-medium text-gray-800">{res.name}</p>
                    <p className="text-xs text-gray-500">{res.service}</p>
                  </div>
                  <span className="text-sm font-semibold text-gray-900">${res.cost.toLocaleString()}</span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-gray-400 text-center py-8">No recommendations yet</p>
          )}
        </div>

        {/* AI Cost Summary */}
        {ai_summary && (
          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <h3 className="text-sm font-semibold text-gray-700 mb-4">AI Workload Costs</h3>
            {ai_summary.by_service_type.length > 0 ? (
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={ai_summary.by_service_type}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="service_type" tick={{ fontSize: 10 }} />
                  <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `$${v}`} />
                  <Tooltip formatter={(v) => `$${v.toLocaleString()}`} />
                  <Bar dataKey="cost" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center py-8">
                <Brain size={32} className="mx-auto text-gray-300 mb-2" />
                <p className="text-sm text-gray-400">No AI workloads detected yet</p>
              </div>
            )}
            {ai_summary.avg_gpu_utilization && (
              <div className="mt-4 flex items-center justify-between text-sm">
                <span className="text-gray-500">Avg GPU Utilization</span>
                <span className={`font-semibold ${ai_summary.avg_gpu_utilization < 30 ? "text-red-500" : "text-green-600"}`}>
                  {ai_summary.avg_gpu_utilization}%
                </span>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

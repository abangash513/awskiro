import React, { useState, useEffect } from "react";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, Cell, PieChart, Pie,
} from "recharts";
import { Brain, Cpu, Zap, Hash, TrendingUp, TrendingDown } from "lucide-react";
import { api } from "../../services/api";
import { useFilters } from "../../contexts/FilterContext";
import GlobalFilters from "../common/GlobalFilters";

const COLORS = ["#8b5cf6", "#3b82f6", "#06b6d4", "#10b981", "#f59e0b", "#ef4444"];

function AIMetricCard({ title, value, subtitle, icon: Icon, iconColor = "text-purple-500", prefix = "$" }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs text-gray-500 font-medium">{title}</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">
            {prefix}{typeof value === "number" ? value.toLocaleString() : value || "—"}
          </p>
          {subtitle && <p className="text-xs text-gray-400 mt-0.5">{subtitle}</p>}
        </div>
        <div className={`p-2 rounded-lg bg-purple-50 ${iconColor}`}>
          <Icon size={18} />
        </div>
      </div>
    </div>
  );
}

export default function AICostsView() {
  const [summary, setSummary] = useState(null);
  const [workloads, setWorkloads] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Use global filter context
  const { filters, getApiParams } = useFilters();

  useEffect(() => {
    setLoading(true);
    
    // Get API params from global filter context
    const params = getApiParams();
    
    Promise.all([api.getAICostSummary(params), api.getAIWorkloads(params)])
      .then(([s, w]) => { setSummary(s); setWorkloads(w); })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [filters.cloudProvider, filters.accountName, filters.businessUnit, filters.timeRange]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-white rounded-xl border border-gray-200 p-5 h-28 animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  if (!summary || summary.total_ai_cost === 0) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">AI Cost Intelligence</h1>
            <p className="text-sm text-gray-500 mt-0.5">Track Azure OpenAI, Cognitive Services, ML, and GPU costs</p>
          </div>
          <GlobalFilters showTimeRange={true} showAccount={true} />
        </div>
        <div className="text-center py-20 bg-white rounded-xl border border-gray-200">
          <Brain size={48} className="mx-auto text-gray-300 mb-4" />
          <h2 className="text-lg font-semibold text-gray-700">No AI workloads detected</h2>
          <p className="text-sm text-gray-400 mt-2 max-w-md mx-auto">
            Connect an Azure subscription with Azure OpenAI, Cognitive Services, or GPU VMs to start tracking AI costs.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">AI Cost Intelligence</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            Azure OpenAI, Cognitive Services, ML Studio, and GPU VM cost tracking
          </p>
        </div>
        <GlobalFilters showTimeRange={true} showAccount={true} />
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <AIMetricCard
          title="Total AI Spend" value={summary.total_ai_cost} icon={Brain}
          subtitle={summary.total_ai_cost_change_percent !== null
            ? `${summary.total_ai_cost_change_percent > 0 ? "+" : ""}${summary.total_ai_cost_change_percent}% vs prior period`
            : null}
        />
        <AIMetricCard
          title="Total Tokens" value={summary.total_tokens} icon={Hash}
          prefix="" iconColor="text-blue-500"
        />
        <AIMetricCard
          title="Cost per 1K Tokens" value={summary.cost_per_1k_tokens_avg?.toFixed(4)} icon={Zap}
          iconColor="text-cyan-500"
        />
        <AIMetricCard
          title="GPU Utilization (Avg)" value={summary.avg_gpu_utilization ? `${summary.avg_gpu_utilization}%` : "—"} icon={Cpu}
          prefix="" iconColor={summary.avg_gpu_utilization && summary.avg_gpu_utilization < 30 ? "text-red-500" : "text-green-500"}
          subtitle={summary.avg_gpu_utilization && summary.avg_gpu_utilization < 30 ? "⚠ Low utilization" : null}
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* AI Cost Trend */}
        <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">AI Spend Trend</h3>
          <ResponsiveContainer width="100%" height={280}>
            <AreaChart data={summary.daily_trend}>
              <defs>
                <linearGradient id="aiGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(d) => new Date(d).toLocaleDateString("en-US", { month: "short", day: "numeric" })} />
              <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `$${v}`} />
              <Tooltip formatter={(v) => [`$${v.toLocaleString()}`, "AI Cost"]} />
              <Area type="monotone" dataKey="cost" stroke="#8b5cf6" strokeWidth={2} fill="url(#aiGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Cost by Model */}
        <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
          <h3 className="text-sm font-semibold text-gray-700 mb-4">Cost by Model</h3>
          {summary.by_model.length > 0 ? (
            <>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie data={summary.by_model} dataKey="cost" nameKey="model" cx="50%" cy="50%" innerRadius={45} outerRadius={75} paddingAngle={2}>
                    {summary.by_model.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                  </Pie>
                  <Tooltip formatter={(v) => `$${v.toLocaleString()}`} />
                </PieChart>
              </ResponsiveContainer>
              <div className="space-y-2 mt-2">
                {summary.by_model.map((m, i) => (
                  <div key={i} className="flex items-center justify-between text-xs">
                    <div className="flex items-center gap-2">
                      <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: COLORS[i % COLORS.length] }} />
                      <span className="text-gray-600 font-medium">{m.model}</span>
                    </div>
                    <div className="text-right">
                      <span className="text-gray-900 font-semibold">${m.cost.toLocaleString()}</span>
                      {m.cost_per_1k_tokens && (
                        <span className="text-gray-400 ml-2">${m.cost_per_1k_tokens}/1K tokens</span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </>
          ) : (
            <p className="text-sm text-gray-400 text-center py-12">No model-level data available</p>
          )}
        </div>
      </div>

      {/* By Service Type */}
      <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">Cost by AI Service</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={summary.by_service_type}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="service_type" tick={{ fontSize: 11 }} />
            <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `$${v.toLocaleString()}`} />
            <Tooltip formatter={(v) => `$${v.toLocaleString()}`} />
            <Bar dataKey="cost" radius={[4, 4, 0, 0]}>
              {summary.by_service_type.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Workloads Table */}
      {workloads.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <h3 className="text-sm font-semibold text-gray-700">AI Workload Details</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="bg-gray-50 text-gray-500 uppercase tracking-wider">
                  <th className="text-left p-3 font-medium">Resource</th>
                  <th className="text-left p-3 font-medium">Type</th>
                  <th className="text-left p-3 font-medium">Model</th>
                  <th className="text-right p-3 font-medium">Cost</th>
                  <th className="text-right p-3 font-medium">Tokens</th>
                  <th className="text-right p-3 font-medium">GPU Util</th>
                  <th className="text-right p-3 font-medium">$/1K Tokens</th>
                </tr>
              </thead>
              <tbody>
                {workloads.slice(0, 20).map((w) => (
                  <tr key={w.id} className="border-t border-gray-100 hover:bg-gray-50">
                    <td className="p-3 font-medium text-gray-800">{w.resource_name || w.deployment_name || "—"}</td>
                    <td className="p-3 text-gray-500">{w.service_type}</td>
                    <td className="p-3 text-gray-500">{w.model_name || "—"}</td>
                    <td className="p-3 text-right font-semibold text-gray-900">${w.total_cost.toLocaleString()}</td>
                    <td className="p-3 text-right text-gray-600">{w.total_tokens?.toLocaleString() || "—"}</td>
                    <td className="p-3 text-right">
                      {w.avg_gpu_utilization !== null ? (
                        <span className={w.avg_gpu_utilization < 30 ? "text-red-500 font-semibold" : "text-gray-600"}>
                          {w.avg_gpu_utilization}%
                        </span>
                      ) : "—"}
                    </td>
                    <td className="p-3 text-right text-gray-600">{w.cost_per_1k_tokens ? `$${w.cost_per_1k_tokens.toFixed(4)}` : "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

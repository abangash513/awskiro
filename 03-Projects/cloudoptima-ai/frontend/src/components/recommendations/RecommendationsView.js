import React, { useState, useEffect } from "react";
import { Lightbulb, Check, X, ChevronDown, DollarSign, AlertTriangle } from "lucide-react";
import { api } from "../../services/api";
import { useFilters } from "../../contexts/FilterContext";
import GlobalFilters from "../common/GlobalFilters";

const CATEGORY_LABELS = {
  rightsizing: "Rightsizing",
  idle_resource: "Idle Resource",
  reserved_instance: "Reserved Instance",
  storage_optimization: "Storage",
  scheduling: "Scheduling",
};

const IMPACT_COLORS = {
  high: "bg-red-100 text-red-700",
  medium: "bg-amber-100 text-amber-700",
  low: "bg-green-100 text-green-700",
};

export default function RecommendationsView() {
  const [recs, setRecs] = useState([]);
  const [summary, setSummary] = useState(null);
  const [filter, setFilter] = useState("open");
  const [categoryFilter, setCategoryFilter] = useState(null);
  const [loading, setLoading] = useState(true);
  
  // Use global filter context
  const { filters, getApiParams } = useFilters();

  const loadData = () => {
    setLoading(true);
    
    // Map frontend filter values to backend status values
    const statusMap = {
      'open': 'new',
      'in_review': 'in_review',
      'accepted': 'accepted',
      'dismissed': 'rejected',
      'implemented': 'implemented',
      'all': null
    };
    
    const backendStatus = statusMap[filter] || null;
    
    // Get API params from global filter context and add local filters
    const params = {
      ...getApiParams(),
      status: backendStatus,
      category: categoryFilter
    };
    
    Promise.all([
      api.getRecommendations(params),
      api.getRecommendationSummary(),
    ])
      .then(([r, s]) => { 
        // Ensure recommendations have status field
        const safeRecs = (r || []).map(rec => ({
          ...rec,
          status: rec.status || 'new',
          impact: rec.impact || 'medium',
          confidence_score: rec.confidence_score || rec.confidence || 0.8
        }));
        
        setRecs(safeRecs); 
        
        // Map API response to component format with safe defaults
        const mappedSummary = {
          total_open: (s.by_status && s.by_status.new) || 0,
          total_monthly_savings: s.potential_monthly_savings || 0,
          total_annual_savings: s.potential_annual_savings || 0,
          by_category: Array.isArray(s.by_category) 
            ? s.by_category.reduce((acc, item) => {
                acc[item.category] = item.count;
                return acc;
              }, {})
            : {}
        };
        setSummary(mappedSummary); 
      })
      .catch(err => {
        console.error('Error loading recommendations:', err);
        setRecs([]);
        setSummary({
          total_open: 0,
          total_monthly_savings: 0,
          total_annual_savings: 0,
          by_category: {}
        });
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => { 
    loadData(); 
  }, [filter, categoryFilter, filters.cloudProvider, filters.accountName, filters.businessUnit]);

  const handleAction = async (id, status, reason = null) => {
    try {
      await api.updateRecommendation(id, { status, dismissed_reason: reason });
      loadData();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Recommendations</h1>
          <p className="text-sm text-gray-500 mt-0.5">Cost optimization opportunities ranked by potential savings</p>
        </div>
        <GlobalFilters showTimeRange={false} showAccount={true} />
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Open Recommendations</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{summary.total_open}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Monthly Savings Potential</p>
            <p className="text-2xl font-bold text-green-600 mt-1">${summary.total_monthly_savings.toLocaleString()}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Annual Savings Potential</p>
            <p className="text-2xl font-bold text-green-600 mt-1">${summary.total_annual_savings.toLocaleString()}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Categories</p>
            <div className="flex flex-wrap gap-1 mt-2">
              {Object.entries(summary.by_category).map(([cat, count]) => (
                <span key={cat} className="text-[10px] bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                  {CATEGORY_LABELS[cat] || cat}: {count}
                </span>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex gap-2 flex-wrap">
        {[
          { value: "open", label: "Open" },
          { value: "in_review", label: "In Review" },
          { value: "accepted", label: "Accepted" },
          { value: "implemented", label: "Implemented" },
          { value: "dismissed", label: "Dismissed" },
          { value: "all", label: "All" }
        ].map((s) => (
          <button key={s.value} onClick={() => setFilter(s.value)}
            className={`px-3 py-1.5 text-xs rounded-lg font-medium transition-colors ${
              filter === s.value ? "bg-blue-600 text-white" : "bg-white text-gray-600 border border-gray-200 hover:bg-gray-50"
            }`}>
            {s.label}
          </button>
        ))}
        <div className="w-px bg-gray-200 mx-1" />
        {[null, "rightsizing", "idle_resource", "reserved_instance", "scheduling"].map((cat) => (
          <button key={cat || "all"} onClick={() => setCategoryFilter(cat)}
            className={`px-3 py-1.5 text-xs rounded-lg font-medium transition-colors ${
              categoryFilter === cat ? "bg-purple-600 text-white" : "bg-white text-gray-600 border border-gray-200 hover:bg-gray-50"
            }`}>
            {cat ? CATEGORY_LABELS[cat] : "All Types"}
          </button>
        ))}
      </div>

      {/* Recommendations List */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="bg-white rounded-xl border border-gray-200 p-5 h-24 animate-pulse" />
          ))}
        </div>
      ) : recs.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <Lightbulb size={40} className="mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">No recommendations found</p>
        </div>
      ) : (
        <div className="space-y-3">
          {recs.map((rec) => (
            <div key={rec.id} className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm hover:border-blue-200 transition-colors">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${IMPACT_COLORS[rec.impact] || 'bg-gray-100 text-gray-700'}`}>
                      {(rec.impact || 'unknown').toUpperCase()}
                    </span>
                    <span className="text-[10px] text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">
                      {CATEGORY_LABELS[rec.category] || rec.category}
                    </span>
                    <span className="text-[10px] text-gray-400">
                      Confidence: {((rec.confidence_score || rec.confidence || 0) * 100).toFixed(0)}%
                    </span>
                  </div>
                  <h3 className="text-sm font-semibold text-gray-900">{rec.title}</h3>
                  <p className="text-xs text-gray-500 mt-1 leading-relaxed">{rec.description}</p>
                </div>
                <div className="text-right ml-6 shrink-0">
                  <p className="text-lg font-bold text-green-600">${(rec.estimated_monthly_savings || 0).toLocaleString()}/mo</p>
                  <p className="text-[10px] text-gray-400">${(rec.estimated_annual_savings || 0).toLocaleString()}/yr</p>
                </div>
              </div>

              {/* Actions */}
              {(rec.status === "new" || rec.status === "open") && (
                <div className="flex gap-2 mt-4 pt-3 border-t border-gray-100">
                  <button onClick={() => handleAction(rec.id, "implemented")}
                    className="flex items-center gap-1 px-3 py-1.5 text-xs bg-green-50 text-green-700 rounded-lg hover:bg-green-100 font-medium">
                    <Check size={12} /> Implemented
                  </button>
                  <button onClick={() => handleAction(rec.id, "accepted")}
                    className="flex items-center gap-1 px-3 py-1.5 text-xs bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 font-medium">
                    Accept
                  </button>
                  <button onClick={() => handleAction(rec.id, "rejected", "Not applicable")}
                    className="flex items-center gap-1 px-3 py-1.5 text-xs bg-gray-50 text-gray-500 rounded-lg hover:bg-gray-100 font-medium">
                    <X size={12} /> Dismiss
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

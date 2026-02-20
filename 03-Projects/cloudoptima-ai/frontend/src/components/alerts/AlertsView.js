import React, { useState, useEffect } from "react";
import { AlertTriangle, AlertCircle, Info, CheckCircle, X, Filter } from "lucide-react";
import { api } from "../../services/api";
import { useFilters } from "../../contexts/FilterContext";
import GlobalFilters from "../common/GlobalFilters";

const SEVERITY_CONFIG = {
  critical: {
    icon: AlertTriangle,
    color: "text-red-600",
    bg: "bg-red-50",
    border: "border-red-200",
    badge: "bg-red-100 text-red-700"
  },
  warning: {
    icon: AlertCircle,
    color: "text-amber-600",
    bg: "bg-amber-50",
    border: "border-amber-200",
    badge: "bg-amber-100 text-amber-700"
  },
  info: {
    icon: Info,
    color: "text-blue-600",
    bg: "bg-blue-50",
    border: "border-blue-200",
    badge: "bg-blue-100 text-blue-700"
  }
};

const TYPE_LABELS = {
  budget: "Budget Alert",
  anomaly: "Cost Anomaly",
  threshold: "Threshold Breach",
  recommendation: "New Recommendation",
  connection: "Connection Issue"
};

function AlertCard({ alert, onDismiss, onMarkRead }) {
  const config = SEVERITY_CONFIG[alert.severity] || SEVERITY_CONFIG.info;
  const Icon = config.icon;

  return (
    <div className={`${config.bg} border ${config.border} rounded-xl p-4 ${alert.read ? 'opacity-60' : ''}`}>
      <div className="flex items-start gap-3">
        <Icon size={20} className={`${config.color} mt-0.5 shrink-0`} />
        
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2 mb-1">
            <div className="flex items-center gap-2 flex-wrap">
              <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${config.badge}`}>
                {alert.severity.toUpperCase()}
              </span>
              <span className="text-xs text-gray-500 bg-white px-2 py-0.5 rounded-full">
                {TYPE_LABELS[alert.type] || alert.type}
              </span>
            </div>
            <span className="text-xs text-gray-400 shrink-0">{alert.timestamp}</span>
          </div>

          <h3 className="text-sm font-semibold text-gray-900 mb-1">{alert.title}</h3>
          <p className="text-sm text-gray-700 leading-relaxed">{alert.message}</p>

          {alert.details && (
            <div className="mt-2 p-2 bg-white rounded border border-gray-200">
              <p className="text-xs text-gray-600">{alert.details}</p>
            </div>
          )}

          <div className="flex gap-2 mt-3">
            {!alert.read && (
              <button
                onClick={() => onMarkRead(alert.id)}
                className="text-xs px-3 py-1 bg-white border border-gray-300 text-gray-700 rounded hover:bg-gray-50 font-medium"
              >
                Mark as Read
              </button>
            )}
            <button
              onClick={() => onDismiss(alert.id)}
              className="text-xs px-3 py-1 bg-white border border-gray-300 text-gray-700 rounded hover:bg-gray-50 font-medium"
            >
              Dismiss
            </button>
            {alert.action_url && (
              <button className="text-xs px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 font-medium">
                View Details →
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function AlertsView() {
  const [alerts, setAlerts] = useState([]);
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filterSeverity, setFilterSeverity] = useState(null);
  const [filterType, setFilterType] = useState(null);
  const [showRead, setShowRead] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      // POC: Use mock data since backend doesn't have alerts endpoint yet
      const mockAlerts = [
        {
          id: 1,
          severity: "critical",
          type: "budget",
          title: "AI/ML Workloads Budget Exceeded",
          message: "Your AI/ML Workloads budget has been exceeded by $245.80 (108% of $3,000 monthly budget)",
          details: "Resource Group: prod-rg | Period: Feb 2026",
          timestamp: "2 hours ago",
          read: false,
          action_url: "/budgets"
        },
        {
          id: 2,
          severity: "critical",
          type: "anomaly",
          title: "Unusual Spending Spike Detected",
          message: "Spending on Virtual Machines increased by 340% compared to last week",
          details: "Current: $2,450/day | Average: $556/day | Anomaly detected in eastus region",
          timestamp: "3 hours ago",
          read: false,
          action_url: "/costs"
        },
        {
          id: 3,
          severity: "warning",
          type: "budget",
          title: "Production Environment: 85% Budget Alert",
          message: "Production Environment has reached 85% of monthly budget ($4,234.50 of $5,000)",
          details: "Projected to exceed budget by Feb 28 at current rate",
          timestamp: "5 hours ago",
          read: false,
          action_url: "/budgets"
        },
        {
          id: 4,
          severity: "warning",
          type: "threshold",
          title: "High GPU Utilization Cost",
          message: "GPU costs exceeded $500/day threshold for 3 consecutive days",
          details: "Service: Azure Machine Learning | Resource: ml-gpu-cluster-01",
          timestamp: "1 day ago",
          read: false,
          action_url: "/ai-costs"
        },
        {
          id: 5,
          severity: "warning",
          type: "anomaly",
          title: "Storage Cost Increase",
          message: "Storage costs increased by 45% this week",
          details: "Current: $456/week | Previous: $314/week | Service: Storage Accounts",
          timestamp: "1 day ago",
          read: true,
          action_url: "/costs"
        },
        {
          id: 6,
          severity: "info",
          type: "recommendation",
          title: "New Cost Optimization Recommendations",
          message: "5 new recommendations available with potential savings of $1,234/month",
          details: "Categories: Rightsizing (3), Idle Resources (2)",
          timestamp: "2 days ago",
          read: false,
          action_url: "/recommendations"
        },
        {
          id: 7,
          severity: "critical",
          type: "threshold",
          title: "Daily Spend Limit Exceeded",
          message: "Daily spending exceeded $1,000 limit by $234",
          details: "Total spend today: $1,234 | Limit: $1,000",
          timestamp: "2 days ago",
          read: true,
          action_url: "/costs"
        },
        {
          id: 8,
          severity: "warning",
          type: "budget",
          title: "Compute Resources: 90% Budget Alert",
          message: "Compute Resources has reached 90% of monthly budget ($3,567.90 of $4,000)",
          details: "Projected overage: $234 by end of month",
          timestamp: "3 days ago",
          read: true,
          action_url: "/budgets"
        },
        {
          id: 9,
          severity: "info",
          type: "connection",
          title: "Cloud Connection Sync Completed",
          message: "Successfully synced cost data from Production Azure subscription",
          details: "Records imported: 1,234 | Last sync: 3 days ago",
          timestamp: "3 days ago",
          read: true,
          action_url: "/connections"
        },
        {
          id: 10,
          severity: "warning",
          type: "anomaly",
          title: "Unusual Weekend Activity",
          message: "Weekend costs 85% higher than typical weekend baseline",
          details: "This weekend: $1,850 | Typical: $1,000 | Possible cause: Unscheduled workloads",
          timestamp: "4 days ago",
          read: true,
          action_url: "/costs"
        }
      ];

      setAlerts(mockAlerts);

      const unreadCount = mockAlerts.filter(a => !a.read).length;
      const criticalCount = mockAlerts.filter(a => a.severity === 'critical' && !a.read).length;
      const warningCount = mockAlerts.filter(a => a.severity === 'warning' && !a.read).length;

      setSummary({
        total: mockAlerts.length,
        unread: unreadCount,
        critical: criticalCount,
        warning: warningCount
      });
    } catch (err) {
      console.error("Failed to load alerts:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleDismiss = (id) => {
    setAlerts(alerts.filter(a => a.id !== id));
    setSummary(prev => ({ ...prev, total: prev.total - 1 }));
  };

  const handleMarkRead = (id) => {
    setAlerts(alerts.map(a => a.id === id ? { ...a, read: true } : a));
    setSummary(prev => ({ ...prev, unread: prev.unread - 1 }));
  };

  const filteredAlerts = alerts.filter(alert => {
    if (!showRead && alert.read) return false;
    if (filterSeverity && alert.severity !== filterSeverity) return false;
    if (filterType && alert.type !== filterType) return false;
    return true;
  });

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-gray-200 rounded w-48 animate-pulse" />
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="h-32 bg-gray-200 rounded-xl animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Alerts & Notifications</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            Monitor cost anomalies, budget alerts, and system notifications
          </p>
        </div>
        <GlobalFilters showTimeRange={false} showAccount={true} />
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Total Alerts</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{summary.total}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Unread</p>
            <p className="text-2xl font-bold text-blue-600 mt-1">{summary.unread}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Critical</p>
            <p className="text-2xl font-bold text-red-600 mt-1">{summary.critical}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
            <p className="text-xs text-gray-500 font-medium">Warnings</p>
            <p className="text-2xl font-bold text-amber-600 mt-1">{summary.warning}</p>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex items-center gap-2 flex-wrap">
        <Filter size={16} className="text-gray-400" />
        
        {/* Severity Filter */}
        <div className="flex gap-1">
          {[null, "critical", "warning", "info"].map((sev) => (
            <button
              key={sev || "all"}
              onClick={() => setFilterSeverity(sev)}
              className={`px-3 py-1.5 text-xs rounded-lg font-medium capitalize transition-colors ${
                filterSeverity === sev
                  ? "bg-blue-600 text-white"
                  : "bg-white text-gray-600 border border-gray-200 hover:bg-gray-50"
              }`}
            >
              {sev || "All Severity"}
            </button>
          ))}
        </div>

        <div className="w-px h-6 bg-gray-200" />

        {/* Type Filter */}
        <div className="flex gap-1">
          {[null, "budget", "anomaly", "threshold", "recommendation"].map((type) => (
            <button
              key={type || "all"}
              onClick={() => setFilterType(type)}
              className={`px-3 py-1.5 text-xs rounded-lg font-medium transition-colors ${
                filterType === type
                  ? "bg-purple-600 text-white"
                  : "bg-white text-gray-600 border border-gray-200 hover:bg-gray-50"
              }`}
            >
              {type ? TYPE_LABELS[type] : "All Types"}
            </button>
          ))}
        </div>

        <div className="w-px h-6 bg-gray-200" />

        {/* Show Read Toggle */}
        <button
          onClick={() => setShowRead(!showRead)}
          className={`px-3 py-1.5 text-xs rounded-lg font-medium transition-colors ${
            showRead
              ? "bg-green-600 text-white"
              : "bg-white text-gray-600 border border-gray-200 hover:bg-gray-50"
          }`}
        >
          {showRead ? "Showing Read" : "Hide Read"}
        </button>
      </div>

      {/* Alerts List */}
      {filteredAlerts.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <CheckCircle size={40} className="mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">No alerts to display</p>
          <p className="text-gray-400 text-xs mt-1">All caught up!</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filteredAlerts.map(alert => (
            <AlertCard
              key={alert.id}
              alert={alert}
              onDismiss={handleDismiss}
              onMarkRead={handleMarkRead}
            />
          ))}
        </div>
      )}
    </div>
  );
}

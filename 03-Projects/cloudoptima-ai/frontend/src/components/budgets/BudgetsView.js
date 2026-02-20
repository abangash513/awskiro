import React, { useState, useEffect } from "react";
import { DollarSign, TrendingUp, AlertTriangle, Plus, Edit2, Trash2 } from "lucide-react";
import { api } from "../../services/api";
import { useFilters } from "../../contexts/FilterContext";
import GlobalFilters from "../common/GlobalFilters";

function BudgetCard({ budget }) {
  const percentUsed = (budget.spent / budget.amount) * 100;
  const isOverBudget = percentUsed > 100;
  const isWarning = percentUsed > 80 && percentUsed <= 100;
  
  const getProgressColor = () => {
    if (isOverBudget) return "bg-red-500";
    if (isWarning) return "bg-amber-500";
    return "bg-green-500";
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm hover:border-blue-200 transition-colors">
      <div className="flex items-start justify-between mb-3">
        <div>
          <h3 className="text-sm font-semibold text-gray-900">{budget.name}</h3>
          <p className="text-xs text-gray-500 mt-0.5">{budget.scope}</p>
        </div>
        <div className="flex gap-1">
          <button className="p-1 hover:bg-gray-100 rounded text-gray-400 hover:text-gray-600">
            <Edit2 size={14} />
          </button>
          <button className="p-1 hover:bg-gray-100 rounded text-gray-400 hover:text-red-600">
            <Trash2 size={14} />
          </button>
        </div>
      </div>

      <div className="space-y-2">
        <div className="flex items-baseline justify-between">
          <span className="text-2xl font-bold text-gray-900">
            ${budget.spent.toLocaleString()}
          </span>
          <span className="text-sm text-gray-500">
            of ${budget.amount.toLocaleString()}
          </span>
        </div>

        <div className="w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
          <div
            className={`h-full ${getProgressColor()} transition-all`}
            style={{ width: `${Math.min(percentUsed, 100)}%` }}
          />
        </div>

        <div className="flex items-center justify-between text-xs">
          <span className={`font-semibold ${isOverBudget ? "text-red-600" : isWarning ? "text-amber-600" : "text-green-600"}`}>
            {percentUsed.toFixed(1)}% used
          </span>
          <span className="text-gray-500">
            ${(budget.amount - budget.spent).toLocaleString()} remaining
          </span>
        </div>
      </div>

      {budget.alerts && budget.alerts.length > 0 && (
        <div className="mt-3 pt-3 border-t border-gray-100">
          <div className="flex items-center gap-1 text-xs text-amber-600">
            <AlertTriangle size={12} />
            <span>{budget.alerts.length} active alert{budget.alerts.length > 1 ? 's' : ''}</span>
          </div>
        </div>
      )}

      <div className="mt-3 pt-3 border-t border-gray-100 text-xs text-gray-500">
        <div className="flex justify-between">
          <span>Period: {budget.period}</span>
          <span>Resets: {budget.reset_date}</span>
        </div>
      </div>
    </div>
  );
}

function BudgetAlert({ alert }) {
  return (
    <div className="flex items-start gap-3 p-3 bg-amber-50 border border-amber-200 rounded-lg">
      <AlertTriangle size={16} className="text-amber-600 mt-0.5 shrink-0" />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900">{alert.title}</p>
        <p className="text-xs text-gray-600 mt-0.5">{alert.message}</p>
        <p className="text-xs text-gray-400 mt-1">{alert.timestamp}</p>
      </div>
    </div>
  );
}

export default function BudgetsView() {
  const [budgets, setBudgets] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      // POC: Use mock data since backend doesn't have budgets endpoint yet
      const mockBudgets = [
        {
          id: 1,
          name: "Production Environment",
          scope: "Resource Group: prod-rg",
          amount: 5000,
          spent: 4234.50,
          period: "Monthly",
          reset_date: "Mar 1, 2026",
          alerts: [{ id: 1, title: "80% threshold reached" }]
        },
        {
          id: 2,
          name: "Development Environment",
          scope: "Resource Group: dev-rg",
          amount: 2000,
          spent: 1456.30,
          period: "Monthly",
          reset_date: "Mar 1, 2026",
          alerts: []
        },
        {
          id: 3,
          name: "AI/ML Workloads",
          scope: "Tag: workload=ai",
          amount: 3000,
          spent: 3245.80,
          period: "Monthly",
          reset_date: "Mar 1, 2026",
          alerts: [
            { id: 2, title: "Budget exceeded" },
            { id: 3, title: "100% threshold reached" }
          ]
        },
        {
          id: 4,
          name: "Storage Costs",
          scope: "Service: Storage Accounts",
          amount: 1000,
          spent: 456.20,
          period: "Monthly",
          reset_date: "Mar 1, 2026",
          alerts: []
        },
        {
          id: 5,
          name: "Compute Resources",
          scope: "Service: Virtual Machines",
          amount: 4000,
          spent: 3567.90,
          period: "Monthly",
          reset_date: "Mar 1, 2026",
          alerts: [{ id: 4, title: "90% threshold reached" }]
        }
      ];

      const mockAlerts = [
        {
          id: 1,
          budget_id: 1,
          title: "Production Environment: 80% Budget Alert",
          message: "Production Environment has reached 80% of monthly budget ($4,234.50 of $5,000)",
          timestamp: "2 hours ago",
          severity: "warning"
        },
        {
          id: 2,
          budget_id: 3,
          title: "AI/ML Workloads: Budget Exceeded",
          message: "AI/ML Workloads has exceeded monthly budget ($3,245.80 of $3,000)",
          timestamp: "5 hours ago",
          severity: "critical"
        },
        {
          id: 3,
          budget_id: 5,
          title: "Compute Resources: 90% Budget Alert",
          message: "Compute Resources has reached 90% of monthly budget ($3,567.90 of $4,000)",
          timestamp: "1 day ago",
          severity: "warning"
        }
      ];

      setBudgets(mockBudgets);
      setAlerts(mockAlerts);

      const totalBudget = mockBudgets.reduce((sum, b) => sum + b.amount, 0);
      const totalSpent = mockBudgets.reduce((sum, b) => sum + b.spent, 0);
      const overBudgetCount = mockBudgets.filter(b => (b.spent / b.amount) > 1).length;

      setSummary({
        total_budget: totalBudget,
        total_spent: totalSpent,
        over_budget_count: overBudgetCount,
        active_alerts: mockAlerts.length
      });
    } catch (err) {
      console.error("Failed to load budgets:", err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-gray-200 rounded w-48 animate-pulse" />
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-24 bg-gray-200 rounded-xl animate-pulse" />
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
          <h1 className="text-2xl font-bold text-gray-900">Budgets</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            Track spending against budgets and receive alerts
          </p>
        </div>
        <div className="flex gap-2">
          <GlobalFilters showTimeRange={false} showAccount={true} />
          <button
            onClick={() => setShowCreateForm(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
          >
            <Plus size={16} />
            Create Budget
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <div className="flex items-center gap-2 mb-1">
              <DollarSign size={16} className="text-blue-500" />
              <p className="text-xs text-gray-500 font-medium">Total Budget</p>
            </div>
            <p className="text-2xl font-bold text-gray-900">
              ${summary.total_budget.toLocaleString()}
            </p>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <div className="flex items-center gap-2 mb-1">
              <TrendingUp size={16} className="text-green-500" />
              <p className="text-xs text-gray-500 font-medium">Total Spent</p>
            </div>
            <p className="text-2xl font-bold text-gray-900">
              ${summary.total_spent.toLocaleString()}
            </p>
            <p className="text-xs text-gray-500 mt-1">
              {((summary.total_spent / summary.total_budget) * 100).toFixed(1)}% of total
            </p>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <div className="flex items-center gap-2 mb-1">
              <AlertTriangle size={16} className="text-red-500" />
              <p className="text-xs text-gray-500 font-medium">Over Budget</p>
            </div>
            <p className="text-2xl font-bold text-red-600">
              {summary.over_budget_count}
            </p>
            <p className="text-xs text-gray-500 mt-1">
              {budgets.length - summary.over_budget_count} within budget
            </p>
          </div>

          <div className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm">
            <div className="flex items-center gap-2 mb-1">
              <AlertTriangle size={16} className="text-amber-500" />
              <p className="text-xs text-gray-500 font-medium">Active Alerts</p>
            </div>
            <p className="text-2xl font-bold text-amber-600">
              {summary.active_alerts}
            </p>
          </div>
        </div>
      )}

      {/* Budget Alerts */}
      {alerts.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-semibold text-gray-700">Recent Alerts</h2>
          {alerts.map(alert => (
            <BudgetAlert key={alert.id} alert={alert} />
          ))}
        </div>
      )}

      {/* Budgets Grid */}
      <div>
        <h2 className="text-sm font-semibold text-gray-700 mb-3">All Budgets</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {budgets.map(budget => (
            <BudgetCard key={budget.id} budget={budget} />
          ))}
        </div>
      </div>

      {/* Create Budget Form Modal (placeholder) */}
      {showCreateForm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 max-w-md w-full mx-4">
            <h2 className="text-lg font-bold text-gray-900 mb-4">Create Budget</h2>
            <p className="text-sm text-gray-500 mb-4">
              Budget creation form coming soon. This is a POC placeholder.
            </p>
            <button
              onClick={() => setShowCreateForm(false)}
              className="w-full px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 text-sm font-medium"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

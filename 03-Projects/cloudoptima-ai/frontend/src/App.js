import React, { useState, useEffect, createContext, useContext } from "react";
import { BrowserRouter, Routes, Route, Navigate, Link, useLocation } from "react-router-dom";
import {
  LayoutDashboard, DollarSign, Lightbulb, Brain, Link2, Download, Settings, LogOut, Menu, X, PieChart, Bell
} from "lucide-react";

import { api } from "./services/api";
import { FilterProvider } from "./contexts/FilterContext";
import Dashboard from "./components/dashboard/Dashboard";
import CostsView from "./components/costs/CostsView";
import RecommendationsView from "./components/recommendations/RecommendationsView";
import AICostsView from "./components/ai_costs/AICostsView";
import ConnectionsView from "./components/connections/ConnectionsView";
import BudgetsView from "./components/budgets/BudgetsView";
import AlertsView from "./components/alerts/AlertsView";
import SettingsView from "./components/settings/SettingsView";
import LoginPage from "./components/common/LoginPage";

// Auth context
const AuthContext = createContext(null);
export const useAuth = () => useContext(AuthContext);

function AuthProvider({ children }) {
  // POC MODE: Auto-login with mock user (no authentication)
  const [user, setUser] = useState({
    id: 1,
    email: "demo@cloudoptima.ai",
    full_name: "Demo User",
    organization: "Demo Organization"
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // POC MODE: Skip authentication check
    // Uncomment below for real authentication:
    /*
    const token = localStorage.getItem("token");
    if (token) {
      api.setToken(token);
      api.getMe()
        .then(setUser)
        .catch(() => localStorage.removeItem("token"))
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
    */
  }, []);

  const login = async (email, password) => {
    // POC MODE: Mock login (no real authentication)
    // Uncomment below for real authentication:
    /*
    const data = await api.login(email, password);
    localStorage.setItem("token", data.access_token);
    api.setToken(data.access_token);
    const me = await api.getMe();
    setUser(me);
    */
  };

  const logout = () => {
    // POC MODE: Logout disabled
    // Uncomment below for real authentication:
    /*
    localStorage.removeItem("token");
    api.setToken(null);
    setUser(null);
    */
  };

  if (loading) return <div className="flex items-center justify-center h-screen text-gray-500">Loading...</div>;

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

// Sidebar navigation
const NAV_ITEMS = [
  { path: "/", icon: LayoutDashboard, label: "Dashboard" },
  { path: "/costs", icon: DollarSign, label: "Cost Explorer" },
  { path: "/recommendations", icon: Lightbulb, label: "Recommendations" },
  { path: "/budgets", icon: PieChart, label: "Budgets" },
  { path: "/alerts", icon: Bell, label: "Alerts" },
  { path: "/ai-costs", icon: Brain, label: "AI Costs" },
  { path: "/connections", icon: Link2, label: "Connections" },
  { path: "/settings", icon: Settings, label: "Settings" },
];

function Sidebar({ collapsed, setCollapsed }) {
  const location = useLocation();
  const { user, logout } = useAuth();

  return (
    <aside className={`fixed left-0 top-0 h-screen bg-brand-900 text-white transition-all duration-200 z-30 ${collapsed ? "w-16" : "w-56"}`}>
      {/* Logo */}
      <div className="flex items-center h-14 px-4 border-b border-white/10">
        {!collapsed && <span className="font-bold text-lg tracking-tight">CloudOptima<span className="text-blue-300">AI</span></span>}
        <button onClick={() => setCollapsed(!collapsed)} className="ml-auto p-1 hover:bg-white/10 rounded">
          {collapsed ? <Menu size={18} /> : <X size={18} />}
        </button>
      </div>

      {/* Nav */}
      <nav className="mt-4 space-y-1 px-2">
        {NAV_ITEMS.map(({ path, icon: Icon, label }) => {
          const active = location.pathname === path;
          return (
            <Link
              key={path}
              to={path}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                active ? "bg-white/15 text-white" : "text-gray-300 hover:bg-white/10 hover:text-white"
              }`}
            >
              <Icon size={18} />
              {!collapsed && <span>{label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* User */}
      <div className="absolute bottom-0 left-0 right-0 p-3 border-t border-white/10">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-xs font-bold">
            {user?.full_name?.[0] || "U"}
          </div>
          {!collapsed && (
            <div className="flex-1 min-w-0">
              <p className="text-xs font-medium truncate">{user?.full_name}</p>
              <p className="text-[10px] text-gray-400 truncate">{user?.email}</p>
            </div>
          )}
          {!collapsed && (
            <button onClick={logout} className="p-1 hover:bg-white/10 rounded" title="Sign out">
              <LogOut size={14} />
            </button>
          )}
        </div>
      </div>
    </aside>
  );
}

function AppLayout() {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* DEMO BANNER */}
      <div className="fixed top-0 left-0 right-0 bg-gradient-to-r from-amber-500 to-orange-500 text-white py-2 px-4 text-center font-bold text-sm shadow-lg z-50">
        🎯 DEMO MODE - Multi-Account Azure Cost Management Dashboard
      </div>
      
      <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
      <main className={`transition-all duration-200 ${collapsed ? "ml-16" : "ml-56"} mt-10`}>
        <div className="p-6 max-w-7xl mx-auto">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/costs" element={<CostsView />} />
            <Route path="/recommendations" element={<RecommendationsView />} />
            <Route path="/budgets" element={<BudgetsView />} />
            <Route path="/alerts" element={<AlertsView />} />
            <Route path="/ai-costs" element={<AICostsView />} />
            <Route path="/connections" element={<ConnectionsView />} />
            <Route path="/settings" element={<SettingsView />} />
            <Route path="/export" element={<div className="text-gray-500">FOCUS Export — coming soon</div>} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </div>
      </main>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <FilterProvider>
          <AuthRouter />
        </FilterProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

function AuthRouter() {
  const { user } = useAuth();
  return user ? <AppLayout /> : <LoginPage />;
}

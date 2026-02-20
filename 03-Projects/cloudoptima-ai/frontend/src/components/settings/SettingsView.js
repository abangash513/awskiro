import React, { useState } from "react";
import { User, Bell, Cloud, Palette, Save, Check } from "lucide-react";

function SettingSection({ title, description, icon: Icon, children }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
      <div className="flex items-start gap-3 mb-4">
        <div className="p-2 bg-blue-50 rounded-lg">
          <Icon size={20} className="text-blue-600" />
        </div>
        <div>
          <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
          <p className="text-sm text-gray-500 mt-0.5">{description}</p>
        </div>
      </div>
      <div className="space-y-4">
        {children}
      </div>
    </div>
  );
}

function SettingRow({ label, description, children }) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
      <div className="flex-1">
        <p className="text-sm font-medium text-gray-900">{label}</p>
        {description && <p className="text-xs text-gray-500 mt-0.5">{description}</p>}
      </div>
      <div className="ml-4">
        {children}
      </div>
    </div>
  );
}

function Toggle({ enabled, onChange }) {
  return (
    <button
      onClick={() => onChange(!enabled)}
      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
        enabled ? "bg-blue-600" : "bg-gray-300"
      }`}
    >
      <span
        className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
          enabled ? "translate-x-6" : "translate-x-1"
        }`}
      />
    </button>
  );
}

export default function SettingsView() {
  const [saved, setSaved] = useState(false);
  
  // User Preferences
  const [displayName, setDisplayName] = useState("Demo User");
  const [email, setEmail] = useState("demo@cloudoptima.ai");
  const [organization, setOrganization] = useState("Demo Organization");
  
  // Notification Settings
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [budgetAlerts, setBudgetAlerts] = useState(true);
  const [anomalyAlerts, setAnomalyAlerts] = useState(true);
  const [weeklyReports, setWeeklyReports] = useState(true);
  const [recommendationAlerts, setRecommendationAlerts] = useState(false);
  
  // Display Settings
  const [theme, setTheme] = useState("light");
  const [currency, setCurrency] = useState("USD");
  const [dateFormat, setDateFormat] = useState("MM/DD/YYYY");
  
  // Cloud Settings
  const [autoSync, setAutoSync] = useState(true);
  const [syncFrequency, setSyncFrequency] = useState("daily");

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
        <p className="text-sm text-gray-500 mt-0.5">
          Manage your account preferences and notification settings
        </p>
      </div>

      {/* User Profile */}
      <SettingSection
        title="User Profile"
        description="Manage your personal information"
        icon={User}
      >
        <SettingRow label="Display Name">
          <input
            type="text"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-64"
          />
        </SettingRow>
        
        <SettingRow label="Email Address">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-64"
          />
        </SettingRow>
        
        <SettingRow label="Organization">
          <input
            type="text"
            value={organization}
            onChange={(e) => setOrganization(e.target.value)}
            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-64"
          />
        </SettingRow>
      </SettingSection>

      {/* Notification Settings */}
      <SettingSection
        title="Notifications"
        description="Configure how you receive alerts and updates"
        icon={Bell}
      >
        <SettingRow
          label="Email Notifications"
          description="Receive notifications via email"
        >
          <Toggle enabled={emailNotifications} onChange={setEmailNotifications} />
        </SettingRow>
        
        <SettingRow
          label="Budget Alerts"
          description="Get notified when budgets reach thresholds"
        >
          <Toggle enabled={budgetAlerts} onChange={setBudgetAlerts} />
        </SettingRow>
        
        <SettingRow
          label="Cost Anomaly Alerts"
          description="Receive alerts for unusual spending patterns"
        >
          <Toggle enabled={anomalyAlerts} onChange={setAnomalyAlerts} />
        </SettingRow>
        
        <SettingRow
          label="Weekly Cost Reports"
          description="Get weekly summary of your cloud spending"
        >
          <Toggle enabled={weeklyReports} onChange={setWeeklyReports} />
        </SettingRow>
        
        <SettingRow
          label="Recommendation Alerts"
          description="Notify when new cost optimization recommendations are available"
        >
          <Toggle enabled={recommendationAlerts} onChange={setRecommendationAlerts} />
        </SettingRow>
      </SettingSection>

      {/* Display Preferences */}
      <SettingSection
        title="Display Preferences"
        description="Customize how information is displayed"
        icon={Palette}
      >
        <SettingRow label="Theme" description="Choose your preferred color scheme">
          <select
            value={theme}
            onChange={(e) => setTheme(e.target.value)}
            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-40"
          >
            <option value="light">Light</option>
            <option value="dark">Dark</option>
            <option value="auto">Auto</option>
          </select>
        </SettingRow>
        
        <SettingRow label="Currency" description="Default currency for cost display">
          <select
            value={currency}
            onChange={(e) => setCurrency(e.target.value)}
            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-40"
          >
            <option value="USD">USD ($)</option>
            <option value="EUR">EUR (€)</option>
            <option value="GBP">GBP (£)</option>
            <option value="JPY">JPY (¥)</option>
          </select>
        </SettingRow>
        
        <SettingRow label="Date Format" description="How dates are displayed">
          <select
            value={dateFormat}
            onChange={(e) => setDateFormat(e.target.value)}
            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-40"
          >
            <option value="MM/DD/YYYY">MM/DD/YYYY</option>
            <option value="DD/MM/YYYY">DD/MM/YYYY</option>
            <option value="YYYY-MM-DD">YYYY-MM-DD</option>
          </select>
        </SettingRow>
      </SettingSection>

      {/* Cloud Account Settings */}
      <SettingSection
        title="Cloud Account Management"
        description="Configure cloud connection settings"
        icon={Cloud}
      >
        <SettingRow
          label="Auto-Sync"
          description="Automatically sync cost data from cloud providers"
        >
          <Toggle enabled={autoSync} onChange={setAutoSync} />
        </SettingRow>
        
        <SettingRow
          label="Sync Frequency"
          description="How often to sync cost data"
        >
          <select
            value={syncFrequency}
            onChange={(e) => setSyncFrequency(e.target.value)}
            disabled={!autoSync}
            className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 w-40 disabled:bg-gray-100 disabled:text-gray-400"
          >
            <option value="hourly">Hourly</option>
            <option value="daily">Daily</option>
            <option value="weekly">Weekly</option>
          </select>
        </SettingRow>
        
        <SettingRow label="Connected Accounts">
          <button className="px-4 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium">
            Manage Connections →
          </button>
        </SettingRow>
      </SettingSection>

      {/* Save Button */}
      <div className="flex items-center justify-between bg-white rounded-xl border border-gray-200 p-4 shadow-sm">
        <p className="text-sm text-gray-500">
          {saved ? (
            <span className="flex items-center gap-2 text-green-600">
              <Check size={16} />
              Settings saved successfully
            </span>
          ) : (
            "Make changes to your settings and save"
          )}
        </p>
        <button
          onClick={handleSave}
          className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
        >
          <Save size={16} />
          Save Changes
        </button>
      </div>

      {/* POC Notice */}
      <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
        <p className="text-sm text-amber-800">
          <strong>POC Mode:</strong> Settings changes are not persisted in this demo version. 
          In production, all settings will be saved to your account.
        </p>
      </div>
    </div>
  );
}

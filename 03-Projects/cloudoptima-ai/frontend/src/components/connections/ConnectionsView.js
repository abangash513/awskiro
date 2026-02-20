import React, { useState, useEffect } from "react";
import { Cloud, CheckCircle, AlertCircle, RefreshCw } from "lucide-react";
import { api } from "../../services/api";

const CLOUD_PROVIDERS = {
  aws: { name: "Amazon Web Services", color: "bg-orange-500", icon: "☁️" },
  azure: { name: "Microsoft Azure", color: "bg-blue-500", icon: "⚡" },
  gcp: { name: "Google Cloud Platform", color: "bg-red-500", icon: "🔷" },
  oci: { name: "Oracle Cloud Infrastructure", color: "bg-red-600", icon: "🔴" }
};

function getCloudProvider(subscriptionId) {
  if (subscriptionId.startsWith('aws-')) return 'aws';
  if (subscriptionId.startsWith('sub-azure-')) return 'azure';
  if (subscriptionId.startsWith('gcp-')) return 'gcp';
  if (subscriptionId.startsWith('oci-')) return 'oci';
  return 'unknown';
}

function getAccountName(subscriptionId) {
  const parts = subscriptionId.split('-');
  if (parts.length >= 2) {
    return parts.slice(1).map(p => p.charAt(0).toUpperCase() + p.slice(1)).join(' ');
  }
  return subscriptionId;
}

export default function ConnectionsView() {
  const [connections, setConnections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterProvider, setFilterProvider] = useState(null);

  useEffect(() => {
    loadConnections();
  }, []);

  const loadConnections = async () => {
    setLoading(true);
    try {
      // Get unique accounts from cost summary
      const costData = await api.getCostByService();
      const accounts = new Set();
      
      // Also get from recommendations to ensure we have all accounts
      const recommendations = await api.getRecommendations();
      recommendations.forEach(rec => accounts.add(rec.subscription_id));
      
      // Create connection objects
      const connectionList = Array.from(accounts).map(subId => {
        const provider = getCloudProvider(subId);
        const accountName = getAccountName(subId);
        
        return {
          id: subId,
          subscription_id: subId,
          name: accountName,
          provider: provider,
          status: 'connected',
          last_sync: new Date().toISOString(),
          cost_records: 0,
          recommendations: recommendations.filter(r => r.subscription_id === subId).length
        };
      });

      setConnections(connectionList.sort((a, b) => a.provider.localeCompare(b.provider)));
    } catch (err) {
      console.error('Failed to load connections:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredConnections = filterProvider
    ? connections.filter(c => c.provider === filterProvider)
    : connections;

  const providerCounts = connections.reduce((acc, conn) => {
    acc[conn.provider] = (acc[conn.provider] || 0) + 1;
    return acc;
  }, {});

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-gray-200 rounded w-48 animate-pulse" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[...Array(6)].map((_, i) => (
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
          <h1 className="text-2xl font-bold text-gray-900">Cloud Connections</h1>
          <p className="text-sm text-gray-500 mt-0.5">
            {connections.length} cloud accounts connected across {Object.keys(providerCounts).length} providers
          </p>
        </div>
        <button
          onClick={loadConnections}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
        >
          <RefreshCw size={16} />
          Refresh
        </button>
      </div>

      {/* Provider Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {Object.entries(CLOUD_PROVIDERS).map(([key, provider]) => {
          const count = providerCounts[key] || 0;
          return (
            <button
              key={key}
              onClick={() => setFilterProvider(filterProvider === key ? null : key)}
              className={`text-left p-4 rounded-xl border-2 transition-all ${
                filterProvider === key
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 bg-white hover:border-gray-300'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-2xl">{provider.icon}</span>
                <span className={`text-xs font-semibold px-2 py-1 rounded-full ${provider.color} text-white`}>
                  {count}
                </span>
              </div>
              <p className="text-sm font-semibold text-gray-900">{provider.name}</p>
              <p className="text-xs text-gray-500 mt-0.5">
                {count} {count === 1 ? 'account' : 'accounts'}
              </p>
            </button>
          );
        })}
      </div>

      {/* Connections List */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredConnections.map((conn) => {
          const provider = CLOUD_PROVIDERS[conn.provider] || { name: 'Unknown', color: 'bg-gray-500', icon: '☁️' };
          
          return (
            <div
              key={conn.id}
              className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm hover:border-blue-200 transition-colors"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <span className="text-2xl">{provider.icon}</span>
                  <div>
                    <h3 className="text-sm font-semibold text-gray-900">{conn.name}</h3>
                    <p className="text-xs text-gray-500">{provider.name}</p>
                  </div>
                </div>
                <div className="flex items-center gap-1 text-green-600">
                  <CheckCircle size={16} />
                  <span className="text-xs font-medium">Active</span>
                </div>
              </div>

              <div className="space-y-2 pt-3 border-t border-gray-100">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-500">Account ID</span>
                  <span className="text-gray-900 font-mono text-[10px]">
                    {conn.subscription_id.slice(0, 20)}...
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-500">Recommendations</span>
                  <span className="text-gray-900 font-semibold">{conn.recommendations}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-500">Last Sync</span>
                  <span className="text-gray-900">
                    {new Date(conn.last_sync).toLocaleDateString()}
                  </span>
                </div>
              </div>

              <div className="mt-4 pt-3 border-t border-gray-100">
                <button className="w-full text-xs text-blue-600 hover:text-blue-700 font-medium">
                  View Details →
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {filteredConnections.length === 0 && (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <Cloud size={40} className="mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">No connections found for this provider</p>
        </div>
      )}
    </div>
  );
}

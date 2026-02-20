/**
 * API client for CloudOptima AI backend.
 */

const API_BASE = process.env.REACT_APP_API_URL || "http://localhost:8000";

class ApiClient {
  constructor() {
    this.token = null;
  }

  setToken(token) {
    this.token = token;
  }

  async request(path, options = {}) {
    const headers = { "Content-Type": "application/json", ...options.headers };
    if (this.token) headers["Authorization"] = `Bearer ${this.token}`;

    const res = await fetch(`${API_BASE}${path}`, { ...options, headers });

    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail || "API error");
    }

    if (res.status === 204) return null;
    return res.json();
  }

  // Auth
  login(email, password) {
    return this.request("/api/v1/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
  }

  register(data) {
    return this.request("/api/v1/auth/register", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  getMe() {
    return this.request("/api/v1/auth/me");
  }

  // Dashboard
  getDashboard(days = 30) {
    return this.request(`/api/v1/dashboard/?days=${days}`);
  }

  // Costs
  getCostSummary(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.start_date) urlParams.set("start_date", params.start_date);
    if (params.end_date) urlParams.set("end_date", params.end_date);
    if (params.account_name) urlParams.set("account_name", params.account_name);
    if (params.business_unit) urlParams.set("business_unit", params.business_unit);
    if (params.cloud_provider) urlParams.set("cloud_provider", params.cloud_provider);
    return this.request(`/api/v1/costs/summary?${urlParams}`);
  }

  getCostTrend(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.start_date) urlParams.set("start_date", params.start_date);
    if (params.end_date) urlParams.set("end_date", params.end_date);
    if (params.account_name) urlParams.set("account_name", params.account_name);
    if (params.business_unit) urlParams.set("business_unit", params.business_unit);
    if (params.cloud_provider) urlParams.set("cloud_provider", params.cloud_provider);
    return this.request(`/api/v1/costs/trend?${urlParams}`);
  }

  getCostByService(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.start_date) urlParams.set("start_date", params.start_date);
    if (params.end_date) urlParams.set("end_date", params.end_date);
    if (params.account_name) urlParams.set("account_name", params.account_name);
    if (params.business_unit) urlParams.set("business_unit", params.business_unit);
    if (params.cloud_provider) urlParams.set("cloud_provider", params.cloud_provider);
    return this.request(`/api/v1/costs/by-service?${urlParams}`);
  }

  getCostByResourceGroup(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.start_date) urlParams.set("start_date", params.start_date);
    if (params.end_date) urlParams.set("end_date", params.end_date);
    if (params.account_name) urlParams.set("account_name", params.account_name);
    if (params.business_unit) urlParams.set("business_unit", params.business_unit);
    if (params.cloud_provider) urlParams.set("cloud_provider", params.cloud_provider);
    return this.request(`/api/v1/costs/by-resource-group?${urlParams}`);
  }

  getCostByAccount(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.start_date) urlParams.set("start_date", params.start_date);
    if (params.end_date) urlParams.set("end_date", params.end_date);
    return this.request(`/api/v1/costs/by-account?${urlParams}`);
  }

  getAccounts() {
    return this.request("/api/v1/costs/accounts");
  }

  importCostData(daysBack = 30) {
    return this.request(`/api/v1/costs/import?days_back=${daysBack}`, { method: "POST" });
  }

  // Recommendations
  getRecommendations(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.status) urlParams.set("status", params.status);
    if (params.category) urlParams.set("category", params.category);
    if (params.account_name) urlParams.set("account_name", params.account_name);
    if (params.business_unit) urlParams.set("business_unit", params.business_unit);
    if (params.limit) urlParams.set("limit", params.limit);
    const queryString = urlParams.toString();
    return this.request(`/api/v1/recommendations/${queryString ? '?' + queryString : ''}`);
  }

  getRecommendationSummary() {
    return this.request("/api/v1/recommendations/summary");
  }

  updateRecommendation(id, data) {
    return this.request(`/api/v1/recommendations/${id}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    });
  }

  importAdvisorRecommendations() {
    return this.request("/api/v1/recommendations/import-advisor", { method: "POST" });
  }

  // AI Costs
  getAICostSummary(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.start_date) urlParams.set("start_date", params.start_date);
    if (params.end_date) urlParams.set("end_date", params.end_date);
    if (params.account_name) urlParams.set("account_name", params.account_name);
    if (params.business_unit) urlParams.set("business_unit", params.business_unit);
    if (params.cloud_provider) urlParams.set("cloud_provider", params.cloud_provider);
    return this.request(`/api/v1/ai-costs/summary?${urlParams}`);
  }

  getAIWorkloads(params = {}) {
    const urlParams = new URLSearchParams();
    if (params.service_type) urlParams.set("service_type", params.service_type);
    if (params.start_date) urlParams.set("start_date", params.start_date);
    if (params.end_date) urlParams.set("end_date", params.end_date);
    if (params.account_name) urlParams.set("account_name", params.account_name);
    if (params.business_unit) urlParams.set("business_unit", params.business_unit);
    if (params.cloud_provider) urlParams.set("cloud_provider", params.cloud_provider);
    return this.request(`/api/v1/ai-costs/workloads?${urlParams}`);
  }

  // Connections
  getConnections() {
    return this.request("/api/v1/connections/");
  }

  createConnection(data) {
    return this.request("/api/v1/connections/", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  syncConnection(id) {
    return this.request(`/api/v1/connections/${id}/sync`, { method: "POST" });
  }

  // FOCUS Export
  getFocusExportUrl(startDate, endDate, format = "csv") {
    const params = new URLSearchParams({ start_date: startDate, end_date: endDate, format });
    return `${API_BASE}/api/v1/focus/export?${params}`;
  }
}

export const api = new ApiClient();

/**
 * CloudOptima AI Dashboard
 * Fetches data from the API and renders the dashboard components
 */

const API_BASE = '/api/v1';
let costChart = null;
let serviceChart = null;

// Initialize dashboard on load
document.addEventListener('DOMContentLoaded', () => {
    initializeDashboard();
    // Refresh every 5 minutes
    setInterval(initializeDashboard, 5 * 60 * 1000);
});

async function initializeDashboard() {
    try {
        updateStatus('loading');
        
        // Fetch all data in parallel
        const [health, costs, trends, resources, budgets, alerts, recommendations] = await Promise.allSettled([
            fetchAPI('/health'),
            fetchAPI('/costs/daily?days=30'),
            fetchAPI('/costs/trends'),
            fetchAPI('/costs/top-resources?limit=10'),
            fetchAPI('/budgets/?active_only=true'),
            fetchAPI('/budgets/alerts/unacknowledged'),
            fetchAPI('/recommendations/savings'),
        ]);
        
        // Update status
        if (health.status === 'fulfilled') {
            updateStatus('connected');
        } else {
            updateStatus('error');
        }
        
        // Update last updated time
        document.getElementById('last-updated').textContent = 
            `Updated: ${new Date().toLocaleTimeString()}`;
        
        // Render components
        if (costs.status === 'fulfilled') {
            renderCostSummary(costs.value);
            renderCostChart(costs.value);
        }
        
        if (trends.status === 'fulfilled') {
            renderTrends(trends.value);
        }
        
        if (resources.status === 'fulfilled') {
            renderTopResources(resources.value);
            renderServiceChart(resources.value);
        }
        
        if (budgets.status === 'fulfilled') {
            renderBudgets(budgets.value);
        }
        
        if (alerts.status === 'fulfilled') {
            renderAlerts(alerts.value);
            updateAlertCount(alerts.value.length);
        }
        
        if (recommendations.status === 'fulfilled') {
            renderRecommendationsSummary(recommendations.value);
        }
        
    } catch (error) {
        console.error('Dashboard initialization error:', error);
        updateStatus('error');
    }
}

async function fetchAPI(endpoint) {
    const response = await fetch(`${API_BASE}${endpoint}`);
    if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
    }
    return response.json();
}

function updateStatus(status) {
    const badge = document.getElementById('api-status');
    badge.className = `status-badge status-${status}`;
    badge.textContent = status === 'connected' ? '● Connected' : 
                        status === 'loading' ? 'Connecting...' : '● Disconnected';
}

function formatCurrency(amount, currency = 'USD') {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency,
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
    }).format(amount);
}

function formatNumber(num) {
    return new Intl.NumberFormat('en-US').format(num);
}

// ============================================================================
// Render Functions
// ============================================================================

function renderCostSummary(data) {
    const totalCost = data.total_cost || 0;
    document.getElementById('total-cost').textContent = formatCurrency(totalCost);
}

function renderTrends(data) {
    const trendEl = document.getElementById('cost-trend');
    const change = data.week_over_week_change || 0;
    
    if (change > 0) {
        trendEl.className = 'card-trend positive';
        trendEl.textContent = `↑ ${change.toFixed(1)}% vs last week`;
    } else if (change < 0) {
        trendEl.className = 'card-trend negative';
        trendEl.textContent = `↓ ${Math.abs(change).toFixed(1)}% vs last week`;
    } else {
        trendEl.className = 'card-trend';
        trendEl.textContent = 'No change vs last week';
    }
}

function renderCostChart(data) {
    const ctx = document.getElementById('cost-chart').getContext('2d');
    
    const costs = data.costs || [];
    const labels = costs.map(c => c.date);
    const values = costs.map(c => c.cost);
    
    if (costChart) {
        costChart.destroy();
    }
    
    costChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Daily Cost',
                data: values,
                borderColor: '#0078d4',
                backgroundColor: 'rgba(0, 120, 212, 0.1)',
                fill: true,
                tension: 0.3,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false,
                },
                tooltip: {
                    callbacks: {
                        label: (context) => formatCurrency(context.raw),
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: (value) => '$' + value,
                    }
                },
                x: {
                    ticks: {
                        maxTicksLimit: 10,
                    }
                }
            }
        }
    });
}

function renderServiceChart(resources) {
    const ctx = document.getElementById('service-chart').getContext('2d');
    
    // Group by resource type
    const byType = {};
    for (const res of resources) {
        const type = res.resource_type || 'Unknown';
        byType[type] = (byType[type] || 0) + (res.total_cost || 0);
    }
    
    const sorted = Object.entries(byType)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 6);
    
    const labels = sorted.map(([type]) => type.split('/').pop() || type);
    const values = sorted.map(([, cost]) => cost);
    
    const colors = [
        '#0078d4', '#107c10', '#ff8c00', '#d13438', '#8764b8', '#00b7c3'
    ];
    
    if (serviceChart) {
        serviceChart.destroy();
    }
    
    serviceChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: values,
                backgroundColor: colors,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'right',
                },
                tooltip: {
                    callbacks: {
                        label: (context) => `${context.label}: ${formatCurrency(context.raw)}`,
                    }
                }
            }
        }
    });
}

function renderTopResources(resources) {
    const tbody = document.getElementById('resources-body');
    
    if (!resources || resources.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="3" class="empty-state">
                    <div class="emoji">📊</div>
                    <p>No resource cost data available</p>
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = resources.map(res => `
        <tr>
            <td title="${res.resource_name || 'N/A'}">
                ${truncate(res.resource_name || 'N/A', 30)}
            </td>
            <td title="${res.resource_type || 'N/A'}">
                ${truncate((res.resource_type || '').split('/').pop() || 'N/A', 20)}
            </td>
            <td>${formatCurrency(res.total_cost || 0)}</td>
        </tr>
    `).join('');
}

function renderBudgets(budgets) {
    const container = document.getElementById('budgets-list');
    
    if (!budgets || budgets.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="emoji">📋</div>
                <p>No active budgets configured</p>
                <p><small>Create budgets via the API to track spending</small></p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = budgets.map(budget => {
        const percent = budget.spend_percentage || 0;
        const progressClass = percent >= 100 ? 'danger' : 
                             percent >= 80 ? 'warning' : 'safe';
        
        return `
            <div class="budget-item">
                <div class="budget-header">
                    <span class="budget-name">${escapeHtml(budget.name)}</span>
                    <span class="budget-amount">${formatCurrency(budget.amount)}</span>
                </div>
                <div class="budget-progress">
                    <div class="budget-progress-bar ${progressClass}" 
                         style="width: ${Math.min(percent, 100)}%"></div>
                </div>
                <div class="budget-stats">
                    <span>Spent: ${formatCurrency(budget.current_spend || 0)}</span>
                    <span>${percent.toFixed(1)}%</span>
                </div>
            </div>
        `;
    }).join('');
}

function renderAlerts(alerts) {
    const container = document.getElementById('alerts-list');
    
    if (!alerts || alerts.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="emoji">✅</div>
                <p>No unacknowledged alerts</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = alerts.map(alert => {
        const severity = alert.severity || 'info';
        const time = alert.created_at ? 
            new Date(alert.created_at).toLocaleString() : '';
        
        return `
            <div class="alert-item ${severity}">
                <div class="alert-header">
                    <span class="alert-title">${escapeHtml(alert.message || 'Alert')}</span>
                    <span class="alert-time">${time}</span>
                </div>
                <div class="alert-message">
                    Threshold: ${alert.threshold_percent}% | 
                    Actual: ${(alert.actual_percent || 0).toFixed(1)}%
                </div>
            </div>
        `;
    }).join('');
}

function updateAlertCount(count) {
    document.getElementById('active-alerts').textContent = count;
    document.getElementById('alerts-subtitle').textContent = 
        count === 1 ? 'unacknowledged' : 'unacknowledged';
}

function renderRecommendationsSummary(data) {
    // Update summary card
    const totalPotential = data.total_potential_monthly_savings || 0;
    document.getElementById('potential-savings').textContent = formatCurrency(totalPotential);
    
    const byCategory = data.by_category || {};
    const totalCount = Object.values(byCategory).reduce((sum, c) => sum + (c.count || 0), 0);
    document.getElementById('recommendation-count').textContent = totalCount;
    
    // Render recommendations list
    renderRecommendationsList(data);
}

function renderRecommendationsList(data) {
    const container = document.getElementById('recommendations-list');
    const byCategory = data.by_category || {};
    
    if (Object.keys(byCategory).length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="emoji">🎯</div>
                <p>No recommendations available</p>
                <p><small>Run cost analysis to generate recommendations</small></p>
            </div>
        `;
        return;
    }
    
    const categoryIcons = {
        'idle_resources': '💤',
        'rightsizing': '📐',
        'reserved_instances': '📅',
        'storage_optimization': '💾',
        'cost_optimization': '💰',
        'default': '💡',
    };
    
    const items = Object.entries(byCategory).map(([category, info]) => {
        const icon = categoryIcons[category] || categoryIcons.default;
        const displayName = category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
        const savings = info.monthly_savings || 0;
        const count = info.count || 0;
        
        return `
            <div class="recommendation-item">
                <div class="rec-icon">${icon}</div>
                <div class="rec-content">
                    <div class="rec-title">${displayName}</div>
                    <div class="rec-description">${count} recommendation${count !== 1 ? 's' : ''} available</div>
                    <div class="rec-savings">
                        Potential savings: ${formatCurrency(savings)}/month
                    </div>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = items.join('');
}

// ============================================================================
// Utility Functions
// ============================================================================

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function truncate(str, maxLength) {
    if (!str) return '';
    if (str.length <= maxLength) return str;
    return str.substring(0, maxLength - 3) + '...';
}

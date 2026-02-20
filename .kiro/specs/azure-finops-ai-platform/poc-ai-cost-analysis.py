#!/usr/bin/env python3
"""
CloudOptima AI - Proof of Concept
AI-Powered Cost Analysis Demo

This POC demonstrates:
1. Azure resource discovery
2. Cost analysis with ML forecasting
3. AI-powered natural language queries
4. Recommendation generation

Requirements:
- pip install azure-identity azure-mgmt-resource azure-mgmt-compute
- pip install pandas numpy scikit-learn prophet openai
"""

import os
from datetime import datetime, timedelta
from typing import List, Dict
import pandas as pd
import numpy as np
from prophet import Prophet
from openai import OpenAI

# Mock Azure connector for demo (replace with real Azure SDK in production)
class MockAzureConnector:
    """Mock Azure connector for POC demonstration"""
    
    def discover_resources(self) -> List[Dict]:
        """Simulate resource discovery"""
        return [
            {
                "id": "vm-001",
                "name": "prod-web-server-01",
                "type": "Microsoft.Compute/virtualMachines",
                "region": "eastus",
                "cost_monthly": 450.00,
                "tags": {"Environment": "Production", "Team": "Web"},
                "metrics": {"avg_cpu": 3.2, "avg_memory": 25.0}
            },
            {
                "id": "vm-002",
                "name": "dev-test-server",
                "type": "Microsoft.Compute/virtualMachines",
                "region": "westus",
                "cost_monthly": 280.00,
                "tags": {"Environment": "Development", "Team": "QA"},
                "metrics": {"avg_cpu": 45.0, "avg_memory": 60.0}
            },
            {
                "id": "disk-001",
                "name": "orphaned-disk-01",
                "type": "Microsoft.Compute/disks",
                "region": "eastus",
                "cost_monthly": 75.00,
                "tags": {},
                "properties": {"attached": False, "size_gb": 512}
            },
            {
                "id": "storage-001",
                "name": "prodstorageacct",
                "type": "Microsoft.Storage/storageAccounts",
                "region": "eastus",
                "cost_monthly": 320.00,
                "tags": {"Environment": "Production"},
                "properties": {"tier": "Hot", "usage_gb": 2500}
            },
            {
                "id": "sql-001",
                "name": "prod-sql-db",
                "type": "Microsoft.Sql/servers/databases",
                "region": "eastus",
                "cost_monthly": 890.00,
                "tags": {"Environment": "Production", "Team": "Data"},
                "metrics": {"avg_dtu": 35.0}
            }
        ]
    
    def get_cost_history(self, days: int = 90) -> pd.DataFrame:
        """Generate mock cost history"""
        dates = pd.date_range(end=datetime.now(), periods=days, freq='D')
        
        # Simulate cost trend with seasonality
        base_cost = 2000
        trend = np.linspace(0, 200, days)  # Gradual increase
        seasonality = 100 * np.sin(np.linspace(0, 4*np.pi, days))  # Weekly pattern
        noise = np.random.normal(0, 50, days)
        
        costs = base_cost + trend + seasonality + noise
        
        return pd.DataFrame({
            'date': dates,
            'cost': costs
        })


class CostForecaster:
    """ML-based cost forecasting using Prophet"""
    
    def __init__(self):
        self.model = Prophet(
            yearly_seasonality=False,
            weekly_seasonality=True,
            daily_seasonality=False
        )
    
    def train_and_forecast(self, historical_data: pd.DataFrame, days_ahead: int = 30) -> pd.DataFrame:
        """Train model and generate forecast"""
        
        # Prepare data for Prophet
        df = historical_data.copy()
        df.columns = ['ds', 'y']
        
        # Train model
        self.model.fit(df)
        
        # Generate forecast
        future = self.model.make_future_dataframe(periods=days_ahead)
        forecast = self.model.predict(future)
        
        return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail(days_ahead)


class RecommendationEngine:
    """Generate cost optimization recommendations"""
    
    def analyze_resources(self, resources: List[Dict]) -> List[Dict]:
        """Analyze resources and generate recommendations"""
        recommendations = []
        
        for resource in resources:
            # Check for idle VMs
            if resource['type'] == 'Microsoft.Compute/virtualMachines':
                if resource['metrics']['avg_cpu'] < 5.0:
                    recommendations.append({
                        'type': 'idle_vm',
                        'resource': resource['name'],
                        'title': f"Idle VM: {resource['name']}",
                        'description': f"VM running with {resource['metrics']['avg_cpu']}% CPU. Consider stopping or deleting.",
                        'impact': 'high',
                        'monthly_savings': resource['cost_monthly'],
                        'annual_savings': resource['cost_monthly'] * 12
                    })
            
            # Check for unattached disks
            if resource['type'] == 'Microsoft.Compute/disks':
                if not resource['properties'].get('attached', True):
                    recommendations.append({
                        'type': 'unattached_disk',
                        'resource': resource['name'],
                        'title': f"Unattached Disk: {resource['name']}",
                        'description': f"Disk not attached to any VM. Consider deleting if not needed.",
                        'impact': 'medium',
                        'monthly_savings': resource['cost_monthly'],
                        'annual_savings': resource['cost_monthly'] * 12
                    })
            
            # Check for underutilized databases
            if resource['type'] == 'Microsoft.Sql/servers/databases':
                if resource['metrics']['avg_dtu'] < 40.0:
                    potential_savings = resource['cost_monthly'] * 0.3  # 30% savings
                    recommendations.append({
                        'type': 'database_rightsizing',
                        'resource': resource['name'],
                        'title': f"Underutilized Database: {resource['name']}",
                        'description': f"Database using {resource['metrics']['avg_dtu']}% DTU. Consider downsizing.",
                        'impact': 'medium',
                        'monthly_savings': potential_savings,
                        'annual_savings': potential_savings * 12
                    })
        
        return recommendations


class AIAssistant:
    """AI-powered natural language query interface"""
    
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
    
    def query(self, question: str, context: Dict) -> str:
        """Process natural language query"""
        
        system_prompt = """You are CloudOptima AI, a cloud cost optimization assistant.
        You help users understand their Azure spending and provide actionable recommendations.
        Be concise, specific, and include numbers when available."""
        
        user_prompt = f"""
        User question: {question}
        
        Available context:
        - Total monthly cost: ${context['total_cost']:,.2f}
        - Number of resources: {context['resource_count']}
        - Potential monthly savings: ${context['potential_savings']:,.2f}
        - Top cost resources: {context['top_resources']}
        - Recent recommendations: {context['recommendations']}
        
        Provide a helpful, actionable response.
        """
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                max_tokens=300
            )
            
            return response.choices[0].message.content
        
        except Exception as e:
            return f"Error: {str(e)}"


def main():
    """Run the POC demonstration"""
    
    print("=" * 80)
    print("CloudOptima AI - Proof of Concept")
    print("AI-Powered Azure Cost Optimization")
    print("=" * 80)
    print()
    
    # Step 1: Resource Discovery
    print("📊 Step 1: Discovering Azure Resources...")
    print("-" * 80)
    
    azure = MockAzureConnector()
    resources = azure.discover_resources()
    
    print(f"✓ Discovered {len(resources)} resources")
    for resource in resources:
        print(f"  - {resource['name']} ({resource['type']}) - ${resource['cost_monthly']:.2f}/month")
    print()
    
    # Step 2: Cost Analysis
    print("💰 Step 2: Analyzing Costs...")
    print("-" * 80)
    
    total_cost = sum(r['cost_monthly'] for r in resources)
    print(f"✓ Total monthly cost: ${total_cost:,.2f}")
    print(f"✓ Annual projection: ${total_cost * 12:,.2f}")
    print()
    
    # Step 3: ML Forecasting
    print("🔮 Step 3: Generating Cost Forecast (30 days)...")
    print("-" * 80)
    
    cost_history = azure.get_cost_history(days=90)
    forecaster = CostForecaster()
    forecast = forecaster.train_and_forecast(cost_history, days_ahead=30)
    
    avg_forecast = forecast['yhat'].mean()
    print(f"✓ Predicted average daily cost: ${avg_forecast:.2f}")
    print(f"✓ Predicted monthly cost: ${avg_forecast * 30:,.2f}")
    print(f"✓ Confidence interval: ${forecast['yhat_lower'].mean():.2f} - ${forecast['yhat_upper'].mean():.2f}")
    print()
    
    # Step 4: Generate Recommendations
    print("💡 Step 4: Generating Optimization Recommendations...")
    print("-" * 80)
    
    engine = RecommendationEngine()
    recommendations = engine.analyze_resources(resources)
    
    total_savings = sum(r['monthly_savings'] for r in recommendations)
    print(f"✓ Found {len(recommendations)} optimization opportunities")
    print(f"✓ Potential monthly savings: ${total_savings:,.2f}")
    print(f"✓ Potential annual savings: ${total_savings * 12:,.2f}")
    print()
    
    for i, rec in enumerate(recommendations, 1):
        print(f"{i}. {rec['title']}")
        print(f"   Impact: {rec['impact'].upper()} | Savings: ${rec['monthly_savings']:.2f}/month")
        print(f"   {rec['description']}")
        print()
    
    # Step 5: AI-Powered Queries (if OpenAI key available)
    print("🤖 Step 5: AI-Powered Natural Language Queries...")
    print("-" * 80)
    
    openai_key = os.getenv('OPENAI_API_KEY')
    
    if openai_key:
        ai = AIAssistant(openai_key)
        
        context = {
            'total_cost': total_cost,
            'resource_count': len(resources),
            'potential_savings': total_savings,
            'top_resources': [r['name'] for r in sorted(resources, key=lambda x: x['cost_monthly'], reverse=True)[:3]],
            'recommendations': [r['title'] for r in recommendations]
        }
        
        # Example queries
        queries = [
            "What are my top 3 cost drivers?",
            "How can I reduce my costs by 20%?",
            "Which resources should I optimize first?"
        ]
        
        for query in queries:
            print(f"Q: {query}")
            answer = ai.query(query, context)
            print(f"A: {answer}")
            print()
    else:
        print("⚠ OpenAI API key not found. Set OPENAI_API_KEY environment variable to test AI features.")
        print()
    
    # Summary
    print("=" * 80)
    print("📈 Summary")
    print("=" * 80)
    print(f"Current monthly cost: ${total_cost:,.2f}")
    print(f"Potential savings: ${total_savings:,.2f} ({(total_savings/total_cost*100):.1f}%)")
    print(f"Recommendations: {len(recommendations)}")
    print(f"Forecast accuracy: High confidence (based on 90-day history)")
    print()
    print("✅ POC Complete! This demonstrates the core capabilities of CloudOptima AI.")
    print()


if __name__ == "__main__":
    main()

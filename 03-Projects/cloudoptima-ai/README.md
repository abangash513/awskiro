# CloudOptima AI - Azure FinOps Platform

A comprehensive Azure cost optimization platform built with FastAPI, providing cost analysis, budget management, and intelligent recommendations for reducing cloud spend.

## Features

- **Cost Data Ingestion**: Fetch and store cost data from Azure Cost Management API
- **Cost Analysis**: View aggregated costs by service, resource type, and time period
- **Budget Management**: Create budgets with configurable alert thresholds
- **Automated Alerts**: Get notified when spending approaches or exceeds budgets
- **Optimization Recommendations**: AI-powered suggestions for cost reduction
- **Trend Analysis**: Week-over-week and month-over-month cost comparisons

## Tech Stack

- **Backend**: Python 3.11+ with FastAPI
- **Database**: SQLAlchemy with async support (SQLite/PostgreSQL)
- **Azure SDK**: `azure-mgmt-costmanagement`, `azure-identity`
- **Logging**: structlog with rich formatting
- **Testing**: pytest with async support

## Quick Start

### Prerequisites

- Python 3.11 or higher
- Azure subscription with Cost Management access
- Service Principal with appropriate permissions

### Installation

1. Clone the repository:
```bash
cd ~/clawd/03-Projects/cloudoptima-ai
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure environment:
```bash
cp .env.example .env
# Edit .env with your Azure credentials
```

5. Run the application:
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `AZURE_TENANT_ID` | Azure AD Tenant ID | Yes |
| `AZURE_CLIENT_ID` | Service Principal Client ID | Yes |
| `AZURE_CLIENT_SECRET` | Service Principal Secret | Yes |
| `AZURE_SUBSCRIPTION_ID` | Default Azure Subscription | Yes |
| `DATABASE_URL` | Database connection string | No (defaults to SQLite) |
| `API_DEBUG` | Enable debug mode | No |
| `COST_LOOKBACK_DAYS` | Default days for cost queries | No (default: 30) |

## API Documentation

Once running, access the interactive API documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key Endpoints

#### Costs
- `POST /api/v1/costs/ingest` - Ingest cost data from Azure
- `GET /api/v1/costs/summary` - Get cost summary by service
- `GET /api/v1/costs/daily` - Get daily cost breakdown
- `GET /api/v1/costs/trends` - Get cost trends

#### Budgets
- `POST /api/v1/budgets/` - Create a budget
- `GET /api/v1/budgets/` - List budgets
- `POST /api/v1/budgets/{id}/check` - Check budget thresholds
- `GET /api/v1/budgets/alerts/unacknowledged` - Get active alerts

#### Recommendations
- `POST /api/v1/recommendations/generate` - Generate recommendations
- `GET /api/v1/recommendations/` - List recommendations
- `GET /api/v1/recommendations/savings-summary` - Get potential savings summary
- `PATCH /api/v1/recommendations/{id}/status` - Update recommendation status

#### Azure
- `GET /api/v1/azure/subscriptions` - List accessible subscriptions
- `GET /api/v1/azure/subscriptions/{id}/resource-groups` - List resource groups

## Project Structure

```
cloudoptima-ai/
├── app/
│   ├── api/
│   │   ├── endpoints/
│   │   │   ├── azure.py       # Azure resource endpoints
│   │   │   ├── budgets.py     # Budget management
│   │   │   ├── costs.py       # Cost analysis
│   │   │   ├── health.py      # Health checks
│   │   │   └── recommendations.py
│   │   └── router.py
│   ├── core/
│   │   ├── config.py          # Application settings
│   │   ├── database.py        # Database configuration
│   │   └── logging.py         # Logging setup
│   ├── models/
│   │   ├── budget.py          # Budget & alert models
│   │   ├── cost.py            # Cost record models
│   │   └── recommendation.py  # Recommendation models
│   ├── schemas/               # Pydantic schemas
│   ├── services/
│   │   ├── azure_client.py    # Azure SDK wrapper
│   │   ├── budget_service.py
│   │   ├── cost_service.py
│   │   └── recommendation_service.py
│   └── main.py               # Application entry point
├── tests/
│   ├── conftest.py           # Test fixtures
│   ├── test_budgets.py
│   ├── test_costs.py
│   └── test_health.py
├── .env.example
├── requirements.txt
└── README.md
```

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_budgets.py -v
```

## Azure Permissions

The Service Principal needs the following permissions:

- **Cost Management Reader** on the target subscriptions
- **Reader** on resource groups (for resource enumeration)

## Development

### Code Quality

```bash
# Format code
black app tests
isort app tests

# Type checking
mypy app

# Linting
ruff check app tests
```

### Database Migrations

Using Alembic for migrations:

```bash
# Create a migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head
```

## Architecture

```
┌─────────────────┐     ┌──────────────────┐
│   FastAPI API   │────▶│  Azure Cost Mgmt │
└────────┬────────┘     └──────────────────┘
         │
    ┌────▼────┐
    │ Services │
    └────┬────┘
         │
    ┌────▼────┐
    │ Database │
    └─────────┘
```

## Contributing

1. Create a feature branch
2. Make your changes with tests
3. Run linting and tests
4. Submit a pull request

## License

MIT License - See LICENSE file for details.

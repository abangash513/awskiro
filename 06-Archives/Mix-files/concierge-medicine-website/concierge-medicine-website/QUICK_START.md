# Quick Start Guide - Concierge Medicine Website

## Local Development Setup

### Prerequisites
- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15
- Redis 7

### Installation

1. **Clone the repository**
   ```bash
   cd concierge-medicine-website
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp backend/.env.example backend/.env
   cp frontend/.env.example frontend/.env
   ```

4. **Start Docker services**
   ```bash
   npm run docker:up
   ```

5. **Run development servers**
   ```bash
   npm run dev
   ```

   - Backend: http://localhost:3001
   - Frontend: http://localhost:3000
   - API Health: http://localhost:3001/health

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh-token` - Refresh JWT token
- `POST /api/auth/mfa-setup` - Setup MFA
- `POST /api/auth/verify-mfa` - Verify MFA token

### Patients
- `GET /api/patients/:id` - Get patient profile
- `PUT /api/patients/:id` - Update patient profile
- `GET /api/patients/:id/medical-history` - Get medical history
- `POST /api/patients/:id/medical-history` - Add medical history
- `GET /api/patients/tiers/list` - Get membership tiers

### Appointments
- `GET /api/appointments/available-slots` - Get available slots
- `POST /api/appointments` - Book appointment
- `GET /api/appointments/:id` - Get appointment details
- `DELETE /api/appointments/:id` - Cancel appointment
- `GET /api/appointments/patient/:patientId` - List patient appointments

### Medical Records
- `GET /api/medical-records` - List medical records
- `POST /api/medical-records` - Upload medical record
- `GET /api/medical-records/:id` - Get specific record
- `DELETE /api/medical-records/:id` - Delete record
- `POST /api/medical-records/:id/share` - Share record

### Messages
- `POST /api/messages` - Send message
- `GET /api/messages` - Get message history
- `GET /api/messages/conversation/:userId` - Get conversation
- `PUT /api/messages/:id/read` - Mark as read
- `DELETE /api/messages/:id` - Delete message

### Billing
- `GET /api/billing/invoices` - Get invoices
- `POST /api/billing/payments` - Process payment
- `GET /api/billing/subscription` - Get subscription
- `PUT /api/billing/subscription` - Update subscription

## Testing

### Run Tests
```bash
npm run test
```

### Run Tests in Watch Mode
```bash
npm run test:watch
```

### Run Linter
```bash
npm run lint
```

### Fix Linting Issues
```bash
npm run lint:fix
```

## Database

### Initialize Database
The database is automatically initialized on first server start.

### View Database
```bash
# Connect to PostgreSQL
psql -h localhost -U concierge_user -d concierge_medicine

# List tables
\dt

# View schema
\d table_name
```

### Reset Database
```bash
# Stop services
npm run docker:down

# Remove volumes
docker volume rm concierge-medicine-website_postgres_data concierge-medicine-website_redis_data

# Start services again
npm run docker:up
```

## Troubleshooting

### Port Already in Use
```bash
# Find process using port
lsof -i :3001
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Database Connection Error
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check logs
docker logs concierge-postgres
```

### Redis Connection Error
```bash
# Check if Redis is running
docker ps | grep redis

# Check logs
docker logs concierge-redis
```

### Module Not Found
```bash
# Reinstall dependencies
rm -rf node_modules
npm install
```

## AWS Deployment

### Prerequisites
- AWS Account
- AWS CLI configured
- Docker installed

### Quick Deploy
1. Review `AWS_DEPLOYMENT_GUIDE.md`
2. Complete `DEPLOYMENT_CHECKLIST.md`
3. Run deployment script:
   ```bash
   export AWS_ACCOUNT_ID=your_account_id
   export AWS_REGION=us-east-1
   chmod +x deploy.sh
   ./deploy.sh
   ```

### Manual Deployment
Follow the step-by-step guide in `AWS_DEPLOYMENT_GUIDE.md`

## Project Structure

```
concierge-medicine-website/
├── backend/
│   ├── src/
│   │   ├── database/        # Database connection & migrations
│   │   ├── models/          # Data models
│   │   ├── services/        # Business logic
│   │   ├── middleware/      # Express middleware
│   │   ├── routes/          # API routes
│   │   ├── types/           # TypeScript types
│   │   └── utils/           # Utilities
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── pages/           # Page components
│   │   ├── components/      # Reusable components
│   │   ├── store/           # Redux store
│   │   ├── services/        # API services
│   │   └── types/           # TypeScript types
│   ├── package.json
│   ├── vite.config.ts
│   └── .env.example
├── docker-compose.yml       # Development services
├── docker-compose.prod.yml  # Production services
├── Dockerfile               # Docker image
├── deploy.sh               # Deployment script
├── AWS_DEPLOYMENT_GUIDE.md # AWS deployment guide
└── README.md               # Project README
```

## Environment Variables

### Backend (.env)
```
DATABASE_URL=postgresql://user:password@localhost:5432/db
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_secret_key
STRIPE_SECRET_KEY=sk_test_...
TWILIO_ACCOUNT_SID=...
SENDGRID_API_KEY=...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AGORA_APP_ID=...
```

### Frontend (.env)
```
VITE_API_URL=http://localhost:3001/api
VITE_SOCKET_URL=http://localhost:3001
```

## Common Commands

```bash
# Development
npm run dev              # Start both backend and frontend
npm run dev -w backend  # Start only backend
npm run dev -w frontend # Start only frontend

# Building
npm run build           # Build both
npm run build -w backend
npm run build -w frontend

# Testing
npm run test            # Run all tests
npm run test -w backend
npm run test -w frontend

# Linting
npm run lint            # Lint all
npm run lint:fix        # Fix linting issues

# Docker
npm run docker:up       # Start Docker services
npm run docker:down     # Stop Docker services

# Deployment
./deploy.sh             # Deploy to AWS
```

## Support

- Documentation: See README.md
- AWS Guide: See AWS_DEPLOYMENT_GUIDE.md
- Issues: Create an issue on GitHub
- Email: support@concierge-medicine.com

## License

Proprietary - Concierge Medicine Practice

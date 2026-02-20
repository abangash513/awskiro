# Concierge Medicine Physician Website

A full-stack web application for managing a membership-based medical practice with patient onboarding, appointment scheduling, telemedicine, secure messaging, and billing.

## Project Structure

```
concierge-medicine-website/
├── backend/                 # Node.js/Express API server
│   ├── src/
│   │   ├── index.ts        # Main server entry point
│   │   ├── routes/         # API route handlers
│   │   ├── models/         # Database models
│   │   ├── services/       # Business logic
│   │   ├── middleware/     # Express middleware
│   │   └── utils/          # Utility functions
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
├── frontend/                # React SPA
│   ├── src/
│   │   ├── main.tsx        # React entry point
│   │   ├── App.tsx         # Root component
│   │   ├── pages/          # Page components
│   │   ├── components/     # Reusable components
│   │   ├── store/          # Redux store
│   │   ├── services/       # API client services
│   │   └── types/          # TypeScript types
│   ├── index.html
│   ├── package.json
│   ├── vite.config.ts
│   └── .env.example
├── docker-compose.yml       # Docker services (PostgreSQL, Redis)
├── package.json            # Root workspace configuration
└── README.md
```

## Prerequisites

- Node.js 18+
- Docker and Docker Compose
- npm or yarn

## Getting Started

### 1. Clone and Install Dependencies

```bash
cd concierge-medicine-website
npm install
```

### 2. Set Up Environment Variables

```bash
# Backend
cp backend/.env.example backend/.env

# Frontend
cp frontend/.env.example frontend/.env
```

### 3. Start Docker Services

```bash
npm run docker:up
```

This starts PostgreSQL and Redis containers.

### 4. Run Development Servers

```bash
npm run dev
```

This starts both backend (port 3001) and frontend (port 3000) in development mode.

- Backend API: http://localhost:3001
- Frontend: http://localhost:3000
- API Health: http://localhost:3001/health

## Available Scripts

### Root Level

```bash
npm run dev          # Start both backend and frontend
npm run build        # Build both backend and frontend
npm run test         # Run tests for both
npm run lint         # Lint both projects
npm run docker:up    # Start Docker services
npm run docker:down  # Stop Docker services
```

### Backend

```bash
cd backend
npm run dev          # Start development server with hot reload
npm run build        # Build TypeScript to JavaScript
npm run start        # Run production build
npm run test         # Run tests
npm run lint         # Run ESLint
npm run typecheck    # Check TypeScript types
```

### Frontend

```bash
cd frontend
npm run dev          # Start Vite dev server
npm run build        # Build for production
npm run preview      # Preview production build
npm run test         # Run tests
npm run lint         # Run ESLint
npm run typecheck    # Check TypeScript types
```

## Technology Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: PostgreSQL
- **Cache**: Redis
- **Real-time**: Socket.io
- **Authentication**: JWT + MFA
- **Payments**: Stripe
- **SMS**: Twilio
- **Email**: SendGrid
- **File Storage**: AWS S3
- **Video**: Agora

### Frontend
- **Framework**: React 18
- **Language**: TypeScript
- **Build Tool**: Vite
- **State Management**: Redux Toolkit
- **Data Fetching**: React Query
- **UI Library**: Material-UI
- **Routing**: React Router
- **Real-time**: Socket.io Client

## Database Schema

The application uses PostgreSQL with the following main tables:
- `users` - User accounts (patients, physicians, admins)
- `patients` - Patient profiles and membership info
- `appointments` - Appointment scheduling
- `medical_records` - Patient medical documents
- `messages` - Secure messaging between users
- `payments` - Payment and billing records
- `telemedicine_sessions` - Video conference sessions
- `membership_tiers` - Service tier definitions

## API Endpoints

### Authentication
- `POST /api/auth/register` - Patient registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh-token` - Token refresh

### Patients
- `GET /api/patients/:id` - Get patient profile
- `PUT /api/patients/:id` - Update patient profile
- `GET /api/patients/:id/medical-history` - Get medical history

### Appointments
- `GET /api/appointments/available-slots` - Get available slots
- `POST /api/appointments` - Book appointment
- `GET /api/appointments/:id` - Get appointment details
- `DELETE /api/appointments/:id` - Cancel appointment

### Medical Records
- `GET /api/medical-records` - List records
- `POST /api/medical-records` - Upload record
- `GET /api/medical-records/:id` - Get record
- `POST /api/medical-records/:id/share` - Create share link

### Messaging
- `POST /api/messages` - Send message
- `GET /api/messages` - Get message history
- `PUT /api/messages/:id/read` - Mark as read

### Billing
- `GET /api/billing/invoices` - Get invoices
- `POST /api/billing/payments` - Process payment
- `GET /api/billing/subscription` - Get subscription

## Security Features

- TLS 1.2+ encryption for all communications
- AES-256 encryption for sensitive data at rest
- JWT authentication with MFA support
- Automatic session timeout (30 minutes)
- Comprehensive audit logging
- HIPAA compliance measures
- SQL injection prevention
- XSS protection
- CSRF token validation

## Development Workflow

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -am 'Add feature'`
3. Run tests: `npm run test`
4. Run linter: `npm run lint`
5. Push to branch: `git push origin feature/your-feature`
6. Create a Pull Request

## Testing

### Unit Tests
```bash
npm run test
```

### Property-Based Tests
Property-based tests are included for critical functionality to ensure correctness properties hold across all inputs.

### Integration Tests
Integration tests verify end-to-end workflows and external service integrations.

## Deployment

### Production Build
```bash
npm run build
```

### Docker Deployment
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Troubleshooting

### Port Already in Use
If ports 3000, 3001, 5432, or 6379 are already in use:
```bash
# Change ports in .env files or docker-compose.yml
```

### Database Connection Issues
```bash
# Check if PostgreSQL is running
npm run docker:up

# Reset database
docker-compose down -v
npm run docker:up
```

### Module Not Found
```bash
# Reinstall dependencies
rm -rf node_modules
npm install
```

## Contributing

Please follow the existing code style and ensure all tests pass before submitting pull requests.

## License

Proprietary - Concierge Medicine Practice

## Support

For issues or questions, contact: support@concierge-medicine.com

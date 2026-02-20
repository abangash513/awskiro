FROM public.ecr.aws/docker/library/node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY backend/package*.json ./backend/
COPY frontend/package*.json ./frontend/

# Install dependencies
RUN npm install --legacy-peer-deps
RUN npm install -w backend --legacy-peer-deps
RUN npm install -w frontend --legacy-peer-deps

# Copy source code
COPY . .

# Build backend
RUN npm run build -w backend

# Build frontend
RUN npm run build -w frontend

# Expose ports
EXPOSE 3001 3000

# Start backend
CMD ["npm", "start", "-w", "backend"]

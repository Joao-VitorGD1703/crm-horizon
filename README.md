# HorizonCRM

This is the Horizon CRM project containing both the backend and frontend.

## Getting Started Locally

### Prerequisites

- Node.js (version 18+ recommended)
- npm or yarn

### Setup

1. Install dependencies for both the backend and frontend:
   ```bash
   npm install
   cd admin && npm install && cd ..
   ```

2. Configure environment variables.
   Copy the example `.env` file and fill in your Supabase credentials. Ensure that you are pointing to the correct Horizon Supabase project:
   ```bash
   cp .env.example .env
   ```
   Open the `.env` file and add the `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` and `ADMIN_KEY` for the Horizon project. **Important: Keep the `.env` file out of version control and do not expose these keys in the frontend!**

### Running the Project

You can run both the backend (Express server) and the frontend (Vite app) concurrently using:

```bash
npm run dev
```

This will start:
- The backend API server on port 3000 (usually)
- The frontend admin panel on the Vite default port (e.g., 5173)

### Building for Production

To build the frontend for production, run:

```bash
npm run build
```

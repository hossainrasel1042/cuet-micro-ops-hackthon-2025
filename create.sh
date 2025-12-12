#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Delineate Dashboard Generator${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if we're in the right directory
if [ ! -f "package.json" ] && [ ! -d "docker" ]; then
    echo -e "${YELLOW}Warning: This doesn't look like the delineate project root${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create frontend directory
echo -e "${GREEN}Creating frontend directory structure...${NC}"
mkdir -p frontend/{public,src/{components/{Dashboard,Layout,Common,Charts},services,hooks,utils,types}}

# 1. Create package.json
cat > frontend/package.json << 'EOF'
{
  "name": "delineate-dashboard",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "type-check": "tsc --noEmit",
    "format": "prettier --write \"src/**/*.{ts,tsx,css}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,css}\""
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "@sentry/react": "^8.40.0",
    "@sentry/tracing": "^8.40.0",
    "@opentelemetry/api": "^1.9.0",
    "@opentelemetry/core": "^1.25.1",
    "@opentelemetry/sdk-trace-web": "^1.25.1",
    "@opentelemetry/instrumentation-document-load": "^0.45.0",
    "@opentelemetry/instrumentation-fetch": "^0.57.0",
    "@opentelemetry/exporter-trace-otlp-http": "^0.52.1",
    "@opentelemetry/resources": "^1.25.1",
    "@opentelemetry/semantic-conventions": "^1.25.1",
    "axios": "^1.7.9",
    "socket.io-client": "^4.7.5",
    "recharts": "^2.12.0",
    "date-fns": "^3.6.0",
    "clsx": "^2.1.1",
    "react-hot-toast": "^2.5.0",
    "react-error-boundary": "^4.0.13",
    "lucide-react": "^0.378.0"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@typescript-eslint/eslint-plugin": "^7.15.0",
    "@typescript-eslint/parser": "^7.15.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.20",
    "eslint": "^8.56.0",
    "eslint-plugin-react-hooks": "^4.6.2",
    "eslint-plugin-react-refresh": "^0.4.7",
    "postcss": "^8.4.41",
    "prettier": "^3.3.3",
    "tailwindcss": "^3.4.10",
    "typescript": "^5.5.3",
    "vite": "^5.4.8"
  }
}
EOF

# 2. Create vite.config.ts
cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  },
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          sentry: ['@sentry/react', '@sentry/tracing'],
          opentelemetry: ['@opentelemetry/api', '@opentelemetry/sdk-trace-web'],
          charts: ['recharts'],
          utils: ['date-fns', 'clsx', 'axios']
        }
      }
    }
  }
})
EOF

# 3. Create TypeScript configs
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "types": ["vite/client"]
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

cat > frontend/tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
EOF

# 4. Create environment files
cat > frontend/.env.example << 'EOF'
# API Configuration
VITE_API_URL=http://localhost:3000

# Sentry Configuration
VITE_SENTRY_DSN=

# OpenTelemetry Configuration
VITE_OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318

# Application
VITE_APP_NAME="Delineate Dashboard"
VITE_APP_VERSION=1.0.0
EOF

cp frontend/.env.example frontend/.env.local

# 5. Create index.html
cat > frontend/index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Delineate Observability Dashboard</title>
    <meta name="description" content="Real-time observability dashboard for Delineate download service">
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# 6. Create main.tsx
cat > frontend/src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'
import { initSentry } from './services/sentry.ts'
import { initOpenTelemetry } from './services/opentelemetry.ts'

// Initialize observability tools
initSentry()
initOpenTelemetry()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

# 7. Create index.css with Tailwind
cat > frontend/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-gray-50 text-gray-900 antialiased;
  }
}

@layer components {
  .card {
    @apply bg-white rounded-xl shadow-sm border border-gray-200;
  }
  
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed;
  }
  
  .btn-secondary {
    @apply px-4 py-2 bg-gray-100 text-gray-700 font-medium rounded-lg hover:bg-gray-200 transition-colors;
  }
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  @apply bg-gray-100;
}

::-webkit-scrollbar-thumb {
  @apply bg-gray-300 rounded;
}

::-webkit-scrollbar-thumb:hover {
  @apply bg-gray-400;
}
EOF

# 8. Create Tailwind config
cat > frontend/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      animation: {
        'pulse-slow': 'pulse 3s ease-in-out infinite',
        'spin-slow': 'spin 2s linear infinite',
      },
      colors: {
        'success': {
          50: '#f0fdf4',
          100: '#dcfce7',
          500: '#22c55e',
          600: '#16a34a',
        },
        'warning': {
          50: '#fefce8',
          100: '#fef9c3',
          500: '#eab308',
          600: '#ca8a04',
        },
        'error': {
          50: '#fef2f2',
          100: '#fee2e2',
          500: '#ef4444',
          600: '#dc2626',
        },
      }
    },
  },
  plugins: [],
}
EOF

# 9. Create postcss config
cat > frontend/postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# 10. Create ESLint config
cat > frontend/eslint.config.js << 'EOF'
import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from '@typescript-eslint/eslint-plugin'
import tsParser from '@typescript-eslint/parser'

export default [
  {
    ignores: ['dist', 'node_modules'],
  },
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 'latest',
      globals: globals.browser,
      parser: tsParser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
      '@typescript-eslint': tseslint,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': [
        'warn',
        { allowConstantExport: true },
      ],
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'no-console': ['warn', { allow: ['warn', 'error'] }],
    },
  },
]
EOF

# 11. Create services files
cat > frontend/src/services/sentry.ts << 'EOF'
import * as Sentry from '@sentry/react'
import { BrowserTracing } from '@sentry/tracing'
import { Integrations } from '@opentelemetry/sdk-trace-web'

export const initSentry = () => {
  if (!import.meta.env.VITE_SENTRY_DSN) {
    console.warn('Sentry DSN not configured. Error tracking disabled.')
    return
  }

  Sentry.init({
    dsn: import.meta.env.VITE_SENTRY_DSN,
    integrations: [
      new BrowserTracing({
        tracePropagationTargets: [
          'localhost',
          /^https:\/\/api\./,
          import.meta.env.VITE_API_URL || 'http://localhost:3000'
        ],
        tracingOrigins: ['localhost', /^\//]
      }),
      new Sentry.Replay({
        maskAllText: false,
        blockAllMedia: false,
      }),
      new Integrations.BrowserTracing()
    ],
    tracesSampleRate: 0.2,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
    environment: import.meta.env.MODE,
    release: `delineate-dashboard@${import.meta.env.PACKAGE_VERSION || '1.0.0'}`,
    beforeSend(event) {
      event.tags = {
        ...event.tags,
        frontend: 'delineate-dashboard',
        version: import.meta.env.PACKAGE_VERSION || '1.0.0'
      }
      return event
    }
  })

  Sentry.setUser({
    id: localStorage.getItem('user_id') || undefined,
    email: localStorage.getItem('user_email') || undefined
  })
}

export const captureError = (error: Error, context?: Record<string, any>) => {
  Sentry.captureException(error, {
    extra: context,
    tags: {
      component: 'frontend'
    }
  })
}

export const captureMessage = (message: string, level: Sentry.SeverityLevel = 'info') => {
  Sentry.captureMessage(message, level)
}

export const setTraceContext = (traceId: string, spanId?: string) => {
  Sentry.setContext('trace', {
    trace_id: traceId,
    span_id: spanId
  })
}

export { Sentry }
EOF

cat > frontend/src/services/opentelemetry.ts << 'EOF'
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web'
import { SimpleSpanProcessor, ConsoleSpanExporter } from '@opentelemetry/sdk-trace-base'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { Resource } from '@opentelemetry/resources'
import { SEMRESATTRS_SERVICE_NAME, SEMRESATTRS_SERVICE_VERSION } from '@opentelemetry/semantic-conventions'
import { registerInstrumentations } from '@opentelemetry/instrumentation'
import { DocumentLoadInstrumentation } from '@opentelemetry/instrumentation-document-load'
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch'
import { W3CTraceContextPropagator } from '@opentelemetry/core'
import { trace, context, propagation } from '@opentelemetry/api'

let provider: WebTracerProvider | null = null

export const initOpenTelemetry = () => {
  if (!import.meta.env.VITE_OTEL_EXPORTER_OTLP_ENDPOINT) {
    console.warn('OpenTelemetry endpoint not configured. Tracing disabled.')
    return
  }

  const resource = new Resource({
    [SEMRESATTRS_SERVICE_NAME]: 'delineate-dashboard',
    [SEMRESATTRS_SERVICE_VERSION]: import.meta.env.PACKAGE_VERSION || '1.0.0',
    'environment': import.meta.env.MODE
  })

  provider = new WebTracerProvider({
    resource
  })

  const exporter = new OTLPTraceExporter({
    url: `${import.meta.env.VITE_OTEL_EXPORTER_OTLP_ENDPOINT}/v1/traces`,
    headers: {}
  })

  const consoleExporter = new ConsoleSpanExporter()

  provider.addSpanProcessor(new SimpleSpanProcessor(exporter))
  if (import.meta.env.DEV) {
    provider.addSpanProcessor(new SimpleSpanProcessor(consoleExporter))
  }

  provider.register({
    propagator: new W3CTraceContextPropagator()
  })

  registerInstrumentations({
    instrumentations: [
      new DocumentLoadInstrumentation(),
      new FetchInstrumentation({
        propagateTraceHeaderCorsUrls: [
          'http://localhost:3000',
          import.meta.env.VITE_API_URL || ''
        ],
        clearTimingResources: true
      })
    ]
  })

  console.log('OpenTelemetry initialized')
}

export const createSpan = (name: string, attributes?: Record<string, any>) => {
  const tracer = trace.getTracer('delineate-dashboard')
  return tracer.startSpan(name, { attributes })
}

export const getCurrentTraceId = (): string | undefined => {
  const currentSpan = trace.getSpan(context.active())
  return currentSpan?.spanContext().traceId
}

export const getCurrentSpanId = (): string | undefined => {
  const currentSpan = trace.getSpan(context.active())
  return currentSpan?.spanContext().spanId
}

export const getTraceParentHeader = (): string => {
  const currentSpan = trace.getSpan(context.active())
  if (!currentSpan) return ''

  const { traceId, spanId } = currentSpan.spanContext()
  return `00-${traceId}-${spanId}-01`
}

export const setTraceAttributes = (attributes: Record<string, any>) => {
  const currentSpan = trace.getSpan(context.active())
  currentSpan?.setAttributes(attributes)
}

export { trace, context }
EOF

# 12. Create API service
cat > frontend/src/services/api.ts << 'EOF'
import axios, { AxiosInstance } from 'axios'
import { getTraceParentHeader, setTraceAttributes, createSpan } from './opentelemetry'
import { captureError } from './sentry'

export interface DownloadJob {
  id: string
  file_id: number
  status: 'pending' | 'processing' | 'completed' | 'failed'
  started_at: string
  completed_at?: string
  error?: string
  trace_id?: string
}

export interface HealthStatus {
  status: 'healthy' | 'unhealthy'
  checks: {
    storage: 'ok' | 'error'
  }
}

export interface ErrorLog {
  id: string
  message: string
  timestamp: string
  level: 'error' | 'warning' | 'info'
  trace_id?: string
  component: string
  user_id?: string
}

export interface PerformanceMetrics {
  response_times: Array<{
    timestamp: string
    endpoint: string
    duration_ms: number
  }>
  success_rate: number
  total_requests: number
  error_rate: number
}

class APIService {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: import.meta.env.VITE_API_URL || '/api',
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json'
      }
    })

    this.client.interceptors.request.use((config) => {
      const traceParent = getTraceParentHeader()
      if (traceParent) {
        config.headers['traceparent'] = traceParent
      }
      
      const sentryTrace = (window as any).Sentry?.getCurrentHub()
        ?.getScope()
        ?.getSpan()
        ?.toTraceparent()
      
      if (sentryTrace) {
        config.headers['sentry-trace'] = sentryTrace
      }

      config.headers['x-correlation-id'] = crypto.randomUUID()
      config.headers['x-frontend-version'] = import.meta.env.PACKAGE_VERSION || '1.0.0'

      return config
    })

    this.client.interceptors.response.use(
      (response) => {
        const traceId = response.headers['x-trace-id']
        if (traceId) {
          setTraceAttributes({ backend_trace_id: traceId })
        }
        return response
      },
      (error) => {
        captureError(error, {
          url: error.config?.url,
          method: error.config?.method,
          status: error.response?.status,
          trace_id: error.response?.headers?.['x-trace-id']
        })
        return Promise.reject(error)
      }
    )
  }

  async checkHealth(): Promise<HealthStatus> {
    const span = createSpan('api.health-check')
    try {
      const response = await this.client.get<HealthStatus>('/health')
      span.setAttributes({
        'http.status_code': response.status,
        'health.storage': response.data.checks.storage
      })
      return response.data
    } catch (error) {
      span.setStatus({ code: 2, message: error.message })
      throw error
    } finally {
      span.end()
    }
  }

  async initiateDownload(fileId: number): Promise<DownloadJob> {
    const span = createSpan('api.initiate-download', { file_id: fileId })
    try {
      const response = await this.client.post<DownloadJob>('/v1/download/initiate', { file_id: fileId })
      span.setAttributes({
        'http.status_code': response.status,
        'download.job_id': response.data.id,
        'download.status': response.data.status
      })
      return response.data
    } catch (error) {
      span.setStatus({ code: 2, message: error.message })
      throw error
    } finally {
      span.end()
    }
  }

  async checkDownload(fileId: number, sentryTest = false): Promise<any> {
    const span = createSpan('api.check-download', { 
      file_id: fileId,
      sentry_test: sentryTest 
    })
    try {
      const url = `/v1/download/check${sentryTest ? '?sentry_test=true' : ''}`
      const response = await this.client.post(url, { file_id: fileId })
      span.setAttributes({
        'http.status_code': response.status
      })
      return response.data
    } catch (error) {
      span.setStatus({ code: 2, message: error.message })
      if (sentryTest) {
        console.log('Sentry test error captured:', error.message)
      }
      throw error
    } finally {
      span.end()
    }
  }

  async getDownloadJobs(): Promise<DownloadJob[]> {
    const span = createSpan('api.get-download-jobs')
    try {
      const response = await this.client.get<DownloadJob[]>('/v1/download/jobs')
      span.setAttributes({
        'http.status_code': response.status,
        'download.count': response.data.length
      })
      return response.data
    } catch (error) {
      span.setStatus({ code: 2, message: error.message })
      throw error
    } finally {
      span.end()
    }
  }

  async getErrorLogs(): Promise<ErrorLog[]> {
    const span = createSpan('api.get-error-logs')
    try {
      const response = await this.client.get<ErrorLog[]>('/v1/errors')
      span.setAttributes({
        'http.status_code': response.status,
        'error.count': response.data.length
      })
      return response.data
    } catch (error) {
      span.setStatus({ code: 2, message: error.message })
      throw error
    } finally {
      span.end()
    }
  }

  async getPerformanceMetrics(): Promise<PerformanceMetrics> {
    const span = createSpan('api.get-performance-metrics')
    try {
      const response = await this.client.get<PerformanceMetrics>('/v1/metrics')
      span.setAttributes({
        'http.status_code': response.status
      })
      return response.data
    } catch (error) {
      span.setStatus({ code: 2, message: error.message })
      throw error
    } finally {
      span.end()
    }
  }

  async getTrace(traceId: string): Promise<any> {
    const span = createSpan('api.get-trace', { trace_id: traceId })
    try {
      const response = await this.client.get(`/v1/traces/${traceId}`)
      span.setAttributes({
        'http.status_code': response.status
      })
      return response.data
    } catch (error) {
      span.setStatus({ code: 2, message: error.message })
      throw error
    } finally {
      span.end()
    }
  }
}

export const api = new APIService()
EOF

# 13. Create App.tsx
cat > frontend/src/App.tsx << 'EOF'
import React from 'react'
import { Toaster } from 'react-hot-toast'
import ErrorBoundary from './components/Common/ErrorBoundary'
import Dashboard from './components/Dashboard/Dashboard'
import Header from './components/Layout/Header'
import Sidebar from './components/Layout/Sidebar'
import './index.css'

function App() {
  return (
    <ErrorBoundary>
      <div className="min-h-screen bg-gray-50">
        <Header />
        <div className="flex">
          <Sidebar />
          <main className="flex-1 p-6">
            <Dashboard />
          </main>
        </div>
        <Toaster 
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: '#363636',
              color: '#fff',
            },
            success: {
              duration: 3000,
              iconTheme: {
                primary: '#10b981',
                secondary: '#fff',
              },
            },
            error: {
              duration: 5000,
              iconTheme: {
                primary: '#ef4444',
                secondary: '#fff',
              },
            },
          }}
        />
      </div>
    </ErrorBoundary>
  )
}

export default App
EOF

# 14. Create ErrorBoundary component
cat > frontend/src/components/Common/ErrorBoundary.tsx << 'EOF'
import React from 'react'
import { AlertTriangle, RefreshCw, Home } from 'lucide-react'
import { captureError } from '../../services/sentry'

interface Props {
  children: React.ReactNode
  fallback?: React.ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
  eventId: string | null
}

export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = {
      hasError: false,
      error: null,
      eventId: null
    }
  }

  static getDerivedStateFromError(error: Error): State {
    return {
      hasError: true,
      error,
      eventId: null
    }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    const eventId = captureError(error, {
      componentStack: errorInfo.componentStack
    })
    
    this.setState({ eventId })
    
    setTimeout(() => {
      if ((window as any).Sentry?.showReportDialog) {
        ;(window as any).Sentry.showReportDialog({ eventId })
      }
    }, 1000)
  }

  handleReset = () => {
    this.setState({
      hasError: false,
      error: null,
      eventId: null
    })
  }

  handleGoHome = () => {
    window.location.href = '/'
  }

  handleReload = () => {
    window.location.reload()
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback
      }

      return (
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center p-4">
          <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-red-100 rounded-full mb-6">
              <AlertTriangle className="w-8 h-8 text-red-600" />
            </div>
            
            <h2 className="text-2xl font-bold text-gray-900 mb-2">
              Something went wrong
            </h2>
            
            <p className="text-gray-600 mb-6">
              {this.state.error?.message || 'An unexpected error occurred'}
            </p>

            {this.state.eventId && (
              <div className="mb-6 p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-500 mb-1">Error ID:</p>
                <code className="text-xs font-mono text-gray-700 break-all">
                  {this.state.eventId}
                </code>
              </div>
            )}

            <div className="space-y-3">
              <button
                onClick={this.handleReset}
                className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <RefreshCw className="w-4 h-4" />
                Try again
              </button>
              
              <button
                onClick={this.handleReload}
                className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
              >
                Refresh page
              </button>
              
              <button
                onClick={this.handleGoHome}
                className="w-full flex items-center justify-center gap-2 px-4 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <Home className="w-4 h-4" />
                Go to homepage
              </button>
            </div>

            <div className="mt-8 pt-6 border-t border-gray-200">
              <p className="text-sm text-gray-500">
                If the problem persists, please contact support with the error ID above.
              </p>
            </div>
          </div>
        </div>
      )
    }

    return this.props.children
  }
}

export default ErrorBoundary
EOF

# 15. Create Dashboard component
cat > frontend/src/components/Dashboard/Dashboard.tsx << 'EOF'
import React from 'react'
import HealthStatus from './HealthStatus'
import DownloadJobs from './DownloadJobs'
import ErrorLog from './ErrorLog'
import TraceViewer from './TraceViewer'
import PerformanceMetrics from './PerformanceMetrics'
import { Activity } from 'lucide-react'

const Dashboard: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Observability Dashboard</h1>
          <p className="text-gray-600 mt-1">Monitor download service health, errors, and performance</p>
        </div>
        <div className="flex items-center gap-2 text-blue-600">
          <Activity className="w-6 h-6" />
          <span className="text-sm font-medium">Real-time monitoring</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="space-y-6">
          <HealthStatus />
          <PerformanceMetrics />
        </div>
        <div className="space-y-6">
          <DownloadJobs />
          <ErrorLog />
        </div>
      </div>

      <TraceViewer />
    </div>
  )
}

export default Dashboard
EOF

# 16. Create HealthStatus component
cat > frontend/src/components/Dashboard/HealthStatus.tsx << 'EOF'
import React, { useState, useEffect } from 'react'
import { Server, CheckCircle, XCircle, AlertCircle } from 'lucide-react'
import { api } from '../../services/api'
import { createSpan, setTraceAttributes } from '../../services/opentelemetry'
import toast from 'react-hot-toast'

const HealthStatus: React.FC = () => {
  const [health, setHealth] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [lastChecked, setLastChecked] = useState<Date | null>(null)

  const checkHealth = async () => {
    const span = createSpan('ui.health-check')
    try {
      setLoading(true)
      const data = await api.checkHealth()
      setHealth(data)
      setLastChecked(new Date())
      
      setTraceAttributes({
        'health.status': data.status,
        'health.storage': data.checks.storage
      })

      if (data.status === 'healthy') {
        toast.success('API is healthy', { duration: 2000 })
      } else {
        toast.error('API is unhealthy', { duration: 4000 })
      }
    } catch (error) {
      toast.error('Failed to check health', { duration: 4000 })
      setTraceAttributes({
        'health.error': error.message
      })
    } finally {
      setLoading(false)
      span.end()
    }
  }

  useEffect(() => {
    checkHealth()
    const interval = setInterval(checkHealth, 30000)
    return () => clearInterval(interval)
  }, [])

  if (loading && !health) {
    return (
      <div className="bg-white rounded-xl shadow p-6">
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
          <div className="h-8 bg-gray-200 rounded w-3/4"></div>
        </div>
      </div>
    )
  }

  const isHealthy = health?.status === 'healthy'
  const storageOk = health?.checks?.storage === 'ok'

  return (
    <div className="bg-white rounded-xl shadow p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className={`p-3 rounded-lg ${isHealthy ? 'bg-green-100' : 'bg-red-100'}`}>
            <Server className={`w-6 h-6 ${isHealthy ? 'text-green-600' : 'text-red-600'}`} />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">API Health Status</h3>
            <p className="text-sm text-gray-500">
              Last checked: {lastChecked ? lastChecked.toLocaleTimeString() : 'Never'}
            </p>
          </div>
        </div>
        <button
          onClick={checkHealth}
          disabled={loading}
          className="px-4 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? 'Checking...' : 'Refresh'}
        </button>
      </div>

      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {isHealthy ? (
              <CheckCircle className="w-5 h-5 text-green-500" />
            ) : (
              <XCircle className="w-5 h-5 text-red-500" />
            )}
            <span className="text-gray-700">API Service</span>
          </div>
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${isHealthy ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
            {isHealthy ? 'Healthy' : 'Unhealthy'}
          </span>
        </div>

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {storageOk ? (
              <CheckCircle className="w-5 h-5 text-green-500" />
            ) : (
              <AlertCircle className="w-5 h-5 text-red-500" />
            )}
            <span className="text-gray-700">S3 Storage</span>
          </div>
          <span className={`px-3 py-1 rounded-full text-sm font-medium ${storageOk ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
            {storageOk ? 'Connected' : 'Disconnected'}
          </span>
        </div>

        {health?.details && (
          <div className="mt-4 p-4 bg-gray-50 rounded-lg">
            <h4 className="text-sm font-medium text-gray-700 mb-2">Details</h4>
            <pre className="text-xs text-gray-600 overflow-auto">
              {JSON.stringify(health.details, null, 2)}
            </pre>
          </div>
        )}
      </div>
    </div>
  )
}

export default HealthStatus
EOF

# 17. Create DownloadJobs component
cat > frontend/src/components/Dashboard/DownloadJobs.tsx << 'EOF'
import React, { useState, useEffect } from 'react'
import { Download, Clock, CheckCircle, XCircle, AlertCircle, Search, Filter } from 'lucide-react'
import { api, DownloadJob } from '../../services/api'
import { createSpan, setTraceAttributes } from '../../services/opentelemetry'
import { captureError } from '../../services/sentry'
import toast from 'react-hot-toast'
import { formatDistanceToNow } from 'date-fns'

const DownloadJobs: React.FC = () => {
  const [jobs, setJobs] = useState<DownloadJob[]>([])
  const [loading, setLoading] = useState(true)
  const [fileId, setFileId] = useState('70000')
  const [submitting, setSubmitting] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')

  const loadJobs = async () => {
    const span = createSpan('ui.load-download-jobs')
    try {
      setLoading(true)
      const data = await api.getDownloadJobs()
      setJobs(data)
      setTraceAttributes({
        'download.jobs_count': data.length
      })
    } catch (error) {
      captureError(error as Error, { action: 'load-download-jobs' })
      toast.error('Failed to load download jobs')
    } finally {
      setLoading(false)
      span.end()
    }
  }

  const handleInitiateDownload = async () => {
    const span = createSpan('ui.initiate-download', { file_id: parseInt(fileId) })
    setSubmitting(true)
    try {
      const job = await api.initiateDownload(parseInt(fileId))
      setJobs(prev => [job, ...prev])
      toast.success('Download initiated successfully')
      
      setTraceAttributes({
        'download.job_id': job.id,
        'download.status': job.status
      })
    } catch (error) {
      captureError(error as Error, { action: 'initiate-download', fileId })
      toast.error('Failed to initiate download')
    } finally {
      setSubmitting(false)
      span.end()
    }
  }

  const handleTestSentry = async () => {
    const span = createSpan('ui.test-sentry-error')
    setSubmitting(true)
    try {
      await api.checkDownload(parseInt(fileId), true)
      toast.success('Sentry test triggered (check Sentry dashboard)')
    } catch (error) {
      toast('Sentry test error captured', { icon: '✅' })
    } finally {
      setSubmitting(false)
      span.end()
    }
  }

  useEffect(() => {
    loadJobs()
    const interval = setInterval(loadJobs, 10000)
    return () => clearInterval(interval)
  }, [])

  const getStatusIcon = (status: DownloadJob['status']) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-5 h-5 text-green-500" />
      case 'failed':
        return <XCircle className="w-5 h-5 text-red-500" />
      case 'processing':
        return <Clock className="w-5 h-5 text-blue-500 animate-pulse" />
      default:
        return <AlertCircle className="w-5 h-5 text-yellow-500" />
    }
  }

  const getStatusColor = (status: DownloadJob['status']) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800'
      case 'failed':
        return 'bg-red-100 text-red-800'
      case 'processing':
        return 'bg-blue-100 text-blue-800'
      default:
        return 'bg-yellow-100 text-yellow-800'
    }
  }

  const filteredJobs = jobs.filter(job => {
    const matchesSearch = job.file_id.toString().includes(searchTerm) ||
                         job.id.includes(searchTerm)
    const matchesFilter = statusFilter === 'all' || job.status === statusFilter
    return matchesSearch && matchesFilter
  })

  return (
    <div className="bg-white rounded-xl shadow">
      <div className="p-6 border-b">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Download className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Download Jobs</h3>
              <p className="text-sm text-gray-500">
                {jobs.length} total jobs • {jobs.filter(j => j.status === 'processing').length} processing
              </p>
            </div>
          </div>
          
          <button
            onClick={loadJobs}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Refresh
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700">File ID</label>
            <input
              type="number"
              value={fileId}
              onChange={(e) => setFileId(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter file ID"
            />
          </div>
          
          <div className="flex items-end gap-2">
            <button
              onClick={handleInitiateDownload}
              disabled={submitting || !fileId}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {submitting ? 'Starting...' : 'Start Download'}
            </button>
            
            <button
              onClick={handleTestSentry}
              disabled={submitting}
              className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              title="Trigger test error for Sentry"
            >
              Test Sentry
            </button>
          </div>
        </div>

        <div className="flex flex-col md:flex-row gap-4 mb-6">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Search by File ID or Job ID..."
            />
          </div>
          
          <div className="flex items-center gap-2">
            <Filter className="w-5 h-5 text-gray-400" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">All Statuses</option>
              <option value="pending">Pending</option>
              <option value="processing">Processing</option>
              <option value="completed">Completed</option>
              <option value="failed">Failed</option>
            </select>
          </div>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Job ID
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                File ID
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Started
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Trace ID
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {loading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <tr key={i}>
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded animate-pulse"></div></td>
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded animate-pulse"></div></td>
                  <td className="px-6 py-4"><div className="h-6 bg-gray-200 rounded animate-pulse w-20"></div></td>
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded animate-pulse"></div></td>
                  <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded animate-pulse"></div></td>
                </tr>
              ))
            ) : filteredJobs.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                  No download jobs found
                </td>
              </tr>
            ) : (
              filteredJobs.map((job) => (
                <tr key={job.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <code className="text-xs font-mono text-gray-700">{job.id.slice(0, 8)}...</code>
                  </td>
                  <td className="px-6 py-4 font-medium text-gray-900">
                    {job.file_id}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(job.status)}
                      <span className={`px-2 py-1 rounded text-xs font-medium ${getStatusColor(job.status)}`}>
                        {job.status}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">
                    {formatDistanceToNow(new Date(job.started_at), { addSuffix: true })}
                  </td>
                  <td className="px-6 py-4">
                    {job.trace_id ? (
                      <code className="text-xs font-mono text-blue-600 hover:text-blue-800 cursor-pointer">
                        {job.trace_id.slice(0, 16)}...
                      </code>
                    ) : (
                      <span className="text-xs text-gray-400">No trace</span>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default DownloadJobs
EOF

# 18. Create other dashboard components (simplified versions)
cat > frontend/src/components/Dashboard/ErrorLog.tsx << 'EOF'
import React, { useState, useEffect } from 'react'
import { AlertTriangle, Info, XCircle, ExternalLink } from 'lucide-react'
import { api, ErrorLog } from '../../services/api'
import { createSpan } from '../../services/opentelemetry'
import toast from 'react-hot-toast'

const ErrorLog: React.FC = () => {
  const [errors, setErrors] = useState<ErrorLog[]>([])
  const [loading, setLoading] = useState(true)

  const loadErrors = async () => {
    const span = createSpan('ui.load-error-logs')
    try {
      setLoading(true)
      const data = await api.getErrorLogs()
      setErrors(data.slice(0, 10)) // Show latest 10 errors
    } catch (error) {
      toast.error('Failed to load error logs')
    } finally {
      setLoading(false)
      span.end()
    }
  }

  useEffect(() => {
    loadErrors()
    const interval = setInterval(loadErrors, 15000)
    return () => clearInterval(interval)
  }, [])

  const getLevelIcon = (level: ErrorLog['level']) => {
    switch (level) {
      case 'error':
        return <XCircle className="w-4 h-4 text-red-500" />
      case 'warning':
        return <AlertTriangle className="w-4 h-4 text-yellow-500" />
      default:
        return <Info className="w-4 h-4 text-blue-500" />
    }
  }

  const getLevelColor = (level: ErrorLog['level']) => {
    switch (level) {
      case 'error':
        return 'bg-red-100 text-red-800'
      case 'warning':
        return 'bg-yellow-100 text-yellow-800'
      default:
        return 'bg-blue-100 text-blue-800'
    }
  }

  const viewInSentry = (traceId?: string) => {
    if (traceId) {
      window.open(`https://sentry.io/organizations/your-org/issues/?query=trace%3A${traceId}`, '_blank')
    }
  }

  return (
    <div className="bg-white rounded-xl shadow">
      <div className="p-6 border-b">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-red-100 rounded-lg">
              <AlertTriangle className="w-6 h-6 text-red-600" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Error Log</h3>
              <p className="text-sm text-gray-500">Recent errors from Sentry</p>
            </div>
          </div>
          <button
            onClick={loadErrors}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Refresh
          </button>
        </div>
      </div>

      <div className="divide-y divide-gray-200">
        {loading ? (
          Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="p-4">
              <div className="h-4 bg-gray-200 rounded animate-pulse mb-2"></div>
              <div className="h-3 bg-gray-200 rounded animate-pulse w-1/2"></div>
            </div>
          ))
        ) : errors.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            No errors found
          </div>
        ) : (
          errors.map((error) => (
            <div key={error.id} className="p-4 hover:bg-gray-50">
              <div className="flex items-start justify-between mb-2">
                <div className="flex items-center gap-2">
                  {getLevelIcon(error.level)}
                  <span className={`px-2 py-1 rounded text-xs font-medium ${getLevelColor(error.level)}`}>
                    {error.level.toUpperCase()}
                  </span>
                  <span className="text-xs text-gray-500">{error.component}</span>
                </div>
                <span className="text-xs text-gray-400">
                  {new Date(error.timestamp).toLocaleTimeString()}
                </span>
              </div>
              
              <p className="text-sm text-gray-700 mb-2 line-clamp-2">
                {error.message}
              </p>
              
              {error.trace_id && (
                <div className="flex items-center justify-between">
                  <code className="text-xs font-mono text-gray-500">
                    Trace: {error.trace_id.slice(0, 16)}...
                  </code>
                  <button
                    onClick={() => viewInSentry(error.trace_id)}
                    className="flex items-center gap-1 text-xs text-blue-600 hover:text-blue-800"
                  >
                    View in Sentry
                    <ExternalLink className="w-3 h-3" />
                  </button>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}

export default ErrorLog
EOF

cat > frontend/src/components/Dashboard/TraceViewer.tsx << 'EOF'
import React, { useState } from 'react'
import { GitBranch, Search, ExternalLink } from 'lucide-react'
import { api } from '../../services/api'
import { createSpan } from '../../services/opentelemetry'
import toast from 'react-hot-toast'

const TraceViewer: React.FC = () => {
  const [traceId, setTraceId] = useState('')
  const [searching, setSearching] = useState(false)
  const [traceData, setTraceData] = useState<any>(null)

  const searchTrace = async () => {
    if (!traceId.trim()) {
      toast.error('Please enter a Trace ID')
      return
    }

    const span = createSpan('ui.search-trace', { trace_id: traceId })
    setSearching(true)
    try {
      const data = await api.getTrace(traceId)
      setTraceData(data)
      toast.success('Trace found')
    } catch (error) {
      toast.error('Trace not found')
      setTraceData(null)
    } finally {
      setSearching(false)
      span.end()
    }
  }

  const openJaegerUI = () => {
    window.open('http://localhost:16686', '_blank')
  }

  return (
    <div className="bg-white rounded-xl shadow">
      <div className="p-6 border-b">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-100 rounded-lg">
              <GitBranch className="w-6 h-6 text-purple-600" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Trace Viewer</h3>
              <p className="text-sm text-gray-500">Search and view distributed traces</p>
            </div>
          </div>
          <button
            onClick={openJaegerUI}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-purple-600 bg-purple-50 rounded-lg hover:bg-purple-100 transition-colors"
          >
            Open Jaeger UI
            <ExternalLink className="w-4 h-4" />
          </button>
        </div>

        <div className="flex gap-2">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={traceId}
              onChange={(e) => setTraceId(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              placeholder="Enter Trace ID (e.g., abc123def456)"
            />
          </div>
          <button
            onClick={searchTrace}
            disabled={searching}
            className="px-6 py-2 bg-purple-600 text-white font-medium rounded-lg hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {searching ? 'Searching...' : 'Search'}
          </button>
        </div>
      </div>

      <div className="p-6">
        {traceData ? (
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500 mb-1">Trace ID</p>
                <code className="text-sm font-mono text-gray-900 break-all">
                  {traceData.traceId}
                </code>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500 mb-1">Duration</p>
                <p className="text-sm font-medium text-gray-900">
                  {traceData.duration} ms
                </p>
              </div>
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500 mb-1">Spans</p>
                <p className="text-sm font-medium text-gray-900">
                  {traceData.spans?.length || 0} spans
                </p>
              </div>
            </div>

            {traceData.spans && traceData.spans.length > 0 && (
              <div className="border border-gray-200 rounded-lg overflow-hidden">
                <table className="w-full">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Service
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Operation
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Duration
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {traceData.spans.map((span: any, index: number) => (
                      <tr key={index} className="hover:bg-gray-50">
                        <td className="px-4 py-3 text-sm text-gray-900">
                          {span.serviceName}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-700">
                          {span.operationName}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-700">
                          {span.duration} ms
                        </td>
                        <td className="px-4 py-3">
                          <span className={`px-2 py-1 rounded text-xs font-medium ${
                            span.statusCode === 0 ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                          }`}>
                            {span.statusCode === 0 ? 'OK' : 'ERROR'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        ) : (
          <div className="text-center py-12">
            <GitBranch className="w-12 h-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 mb-2">No trace selected</p>
            <p className="text-sm text-gray-400">
              Enter a Trace ID to search for specific traces
            </p>
          </div>
        )}
      </div>
    </div>
  )
}

export default TraceViewer
EOF

cat > frontend/src/components/Dashboard/PerformanceMetrics.tsx << 'EOF'
import React, { useState, useEffect } from 'react'
import { BarChart3, TrendingUp, Clock, Zap } from 'lucide-react'
import { api, PerformanceMetrics as PerformanceMetricsType } from '../../services/api'
import { createSpan } from '../../services/opentelemetry'
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts'

const PerformanceMetrics: React.FC = () => {
  const [metrics, setMetrics] = useState<PerformanceMetricsType | null>(null)
  const [loading, setLoading] = useState(true)

  const loadMetrics = async () => {
    const span = createSpan('ui.load-performance-metrics')
    try {
      setLoading(true)
      const data = await api.getPerformanceMetrics()
      setMetrics(data)
    } catch (error) {
      console.error('Failed to load metrics:', error)
    } finally {
      setLoading(false)
      span.end()
    }
  }

  useEffect(() => {
    loadMetrics()
    const interval = setInterval(loadMetrics, 30000)
    return () => clearInterval(interval)
  }, [])

  if (loading && !metrics) {
    return (
      <div className="bg-white rounded-xl shadow p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-6"></div>
          <div className="h-64 bg-gray-200 rounded"></div>
        </div>
      </div>
    )
  }

  const chartData = metrics?.response_times.slice(-10).map(item => ({
    time: new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    duration: item.duration_ms,
    endpoint: item.endpoint
  })) || []

  return (
    <div className="bg-white rounded-xl shadow p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 rounded-lg">
            <BarChart3 className="w-6 h-6 text-blue-600" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Performance Metrics</h3>
            <p className="text-sm text-gray-500">API response times and success rates</p>
          </div>
        </div>
        <button
          onClick={loadMetrics}
          className="px-4 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
        >
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-gray-50 p-4 rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-green-100 rounded">
              <TrendingUp className="w-4 h-4 text-green-600" />
            </div>
            <span className="text-sm font-medium text-gray-700">Success Rate</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">
            {metrics?.success_rate ? `${(metrics.success_rate * 100).toFixed(1)}%` : 'N/A'}
          </p>
        </div>

        <div className="bg-gray-50 p-4 rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-red-100 rounded">
              <Zap className="w-4 h-4 text-red-600" />
            </div>
            <span className="text-sm font-medium text-gray-700">Error Rate</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">
            {metrics?.error_rate ? `${(metrics.error_rate * 100).toFixed(1)}%` : 'N/A'}
          </p>
        </div>

        <div className="bg-gray-50 p-4 rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-blue-100 rounded">
              <Clock className="w-4 h-4 text-blue-600" />
            </div>
            <span className="text-sm font-medium text-gray-700">Avg Response</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">
            {metrics?.response_times.length 
              ? `${(metrics.response_times.reduce((sum, item) => sum + item.duration_ms, 0) / metrics.response_times.length).toFixed(0)}ms`
              : 'N/A'}
          </p>
        </div>

        <div className="bg-gray-50 p-4 rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-purple-100 rounded">
              <BarChart3 className="w-4 h-4 text-purple-600" />
            </div>
            <span className="text-sm font-medium text-gray-700">Total Requests</span>
          </div>
          <p className="text-2xl font-bold text-gray-900">
            {metrics?.total_requests || '0'}
          </p>
        </div>
      </div>

      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis 
              dataKey="time" 
              stroke="#6b7280"
              fontSize={12}
            />
            <YAxis 
              stroke="#6b7280"
              fontSize={12}
              label={{ value: 'ms', angle: -90, position: 'insideLeft' }}
            />
            <Tooltip
              contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e7eb', borderRadius: '0.5rem' }}
              formatter={(value) => [`${value}ms`, 'Duration']}
            />
            <Legend />
            <Line 
              type="monotone" 
              dataKey="duration" 
              stroke="#3b82f6" 
              strokeWidth={2}
              dot={{ r: 3 }}
              activeDot={{ r: 6 }}
              name="Response Time"
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

export default PerformanceMetrics
EOF

# 19. Create Layout components
cat > frontend/src/components/Layout/Header.tsx << 'EOF'
import React from 'react'
import { Activity, Bell, User, Settings } from 'lucide-react'

const Header: React.FC = () => {
  return (
    <header className="bg-white border-b border-gray-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg">
            <Activity className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">Delineate</h1>
            <p className="text-sm text-gray-500">Observability Dashboard</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <button className="relative p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors">
            <Bell className="w-5 h-5" />
            <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
          </button>
          
          <button className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors">
            <Settings className="w-5 h-5" />
          </button>
          
          <div className="flex items-center gap-3 pl-4 border-l border-gray-200">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-medium">
              A
            </div>
            <div>
              <p className="text-sm font-medium text-gray-900">Admin User</p>
              <p className="text-xs text-gray-500">Administrator</p>
            </div>
          </div>
        </div>
      </div>
    </header>
  )
}

export default Header
EOF

cat > frontend/src/components/Layout/Sidebar.tsx << 'EOF'
import React from 'react'
import { Activity, Download, AlertTriangle, GitBranch, BarChart3, HelpCircle } from 'lucide-react'

const Sidebar: React.FC = () => {
  const menuItems = [
    { icon: Activity, label: 'Dashboard', active: true },
    { icon: Download, label: 'Downloads' },
    { icon: AlertTriangle, label: 'Errors' },
    { icon: GitBranch, label: 'Traces' },
    { icon: BarChart3, label: 'Metrics' },
  ]

  return (
    <aside className="w-64 bg-white border-r border-gray-200 p-6">
      <nav className="space-y-2">
        {menuItems.map((item) => {
          const Icon = item.icon
          return (
            <button
              key={item.label}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                item.active
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`}
            >
              <Icon className="w-5 h-5" />
              <span className="font-medium">{item.label}</span>
            </button>
          )
        })}
      </nav>

      <div className="mt-12">
        <div className="p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl border border-blue-100">
          <HelpCircle className="w-6 h-6 text-blue-600 mb-2" />
          <h4 className="font-medium text-gray-900 mb-1">Need help?</h4>
          <p className="text-sm text-gray-600 mb-3">
            Check our documentation for integration guides
          </p>
          <button className="w-full px-3 py-2 text-sm font-medium text-blue-600 bg-white border border-blue-200 rounded-lg hover:bg-blue-50 transition-colors">
            View Docs
          </button>
        </div>
      </div>

      <div className="mt-8 pt-6 border-t border-gray-200">
        <div className="text-xs text-gray-500 mb-2">Powered by</div>
        <div className="flex items-center gap-3">
          <div className="text-sm font-medium text-gray-900">Sentry</div>
          <div className="w-1 h-1 bg-gray-300 rounded-full"></div>
          <div className="text-sm font-medium text-gray-900">OpenTelemetry</div>
          <div className="w-1 h-1 bg-gray-300 rounded-full"></div>
          <div className="text-sm font-medium text-gray-900">Jaeger</div>
        </div>
      </div>
    </aside>
  )
}

export default Sidebar
EOF

# 20. Create types
cat > frontend/src/types/index.ts << 'EOF'
export interface DownloadJob {
  id: string
  file_id: number
  status: 'pending' | 'processing' | 'completed' | 'failed'
  started_at: string
  completed_at?: string
  error?: string
  trace_id?: string
}

export interface HealthStatus {
  status: 'healthy' | 'unhealthy'
  checks: {
    storage: 'ok' | 'error'
  }
  details?: Record<string, any>
}

export interface ErrorLog {
  id: string
  message: string
  timestamp: string
  level: 'error' | 'warning' | 'info'
  trace_id?: string
  component: string
  user_id?: string
}

export interface PerformanceMetrics {
  response_times: Array<{
    timestamp: string
    endpoint: string
    duration_ms: number
  }>
  success_rate: number
  total_requests: number
  error_rate: number
}

export interface Trace {
  traceId: string
  spans: Array<{
    spanId: string
    operationName: string
    serviceName: string
    startTime: number
    duration: number
    tags: Record<string, any>
  }>
  duration: number
}
EOF

# 21. Create utils
cat > frontend/src/utils/tracing.ts << 'EOF'
export const generateTraceId = (): string => {
  const chars = '0123456789abcdef'
  let result = ''
  for (let i = 0; i < 32; i++) {
    result += chars[Math.floor(Math.random() * chars.length)]
  }
  return result
}

export const formatTraceId = (traceId: string): string => {
  if (traceId.length <= 16) return traceId
  return `${traceId.slice(0, 8)}...${traceId.slice(-8)}`
}

export const parseTraceParent = (header: string) => {
  if (!header) return null
  
  const parts = header.split('-')
  if (parts.length !== 4) return null
  
  return {
    version: parts[0],
    traceId: parts[1],
    parentId: parts[2],
    flags: parts[3]
  }
}

export const createTraceParent = (traceId: string, spanId: string): string => {
  return `00-${traceId}-${spanId}-01`
}
EOF

cat > frontend/src/utils/constants.ts << 'EOF'
export const API_ENDPOINTS = {
  HEALTH: '/health',
  DOWNLOAD_INITIATE: '/v1/download/initiate',
  DOWNLOAD_CHECK: '/v1/download/check',
  DOWNLOAD_JOBS: '/v1/download/jobs',
  ERRORS: '/v1/errors',
  METRICS: '/v1/metrics',
  TRACES: '/v1/traces'
} as const

export const STATUS_COLORS = {
  healthy: 'green',
  unhealthy: 'red',
  pending: 'yellow',
  processing: 'blue',
  completed: 'green',
  failed: 'red'
} as const

export const STATUS_ICONS = {
  healthy: 'CheckCircle',
  unhealthy: 'XCircle',
  pending: 'Clock',
  processing: 'Loader2',
  completed: 'CheckCircle',
  failed: 'XCircle',
  error: 'AlertTriangle',
  warning: 'AlertTriangle',
  info: 'Info'
} as const
EOF

cat > frontend/src/utils/formatters.ts << 'EOF'
export const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes'
  
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

export const formatDuration = (ms: number): string => {
  if (ms < 1000) return `${ms}ms`
  if (ms < 60000) return `${(ms / 1000).toFixed(2)}s`
  return `${(ms / 60000).toFixed(2)}m`
}

export const formatDate = (date: Date | string): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

export const formatTimeAgo = (date: Date | string): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  const now = new Date()
  const diffMs = now.getTime() - d.getTime()
  const diffSec = Math.floor(diffMs / 1000)
  const diffMin = Math.floor(diffSec / 60)
  const diffHour = Math.floor(diffMin / 60)
  const diffDay = Math.floor(diffHour / 24)
  
  if (diffDay > 0) return `${diffDay} day${diffDay > 1 ? 's' : ''} ago`
  if (diffHour > 0) return `${diffHour} hour${diffHour > 1 ? 's' : ''} ago`
  if (diffMin > 0) return `${diffMin} minute${diffMin > 1 ? 's' : ''} ago`
  return 'Just now'
}
EOF

# 22. Create Dockerfile for frontend
cat > frontend/Dockerfile << 'EOF'
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./
RUN npm ci

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy .env file (for runtime environment variables)
COPY .env.production /usr/share/nginx/html/.env

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# 23. Create nginx config
cat > frontend/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API proxy
    location /api/ {
        proxy_pass http://delineate-app:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Trace context headers
        proxy_set_header traceparent $http_traceparent;
        proxy_set_header tracestate $http_tracestate;
    }
}
EOF

# 24. Update main Docker Compose files
echo -e "${GREEN}Updating Docker Compose files...${NC}"

# Update docker/compose.dev.yml
cat >> docker/compose.dev.yml << 'EOF'

  frontend:
    build:
      context: ../frontend
      dockerfile: Dockerfile
    ports:
      - "5173:5173"
    environment:
      - VITE_API_URL=http://delineate-app:3000
      - VITE_OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
    depends_on:
      - delineate-app
      - otel-collector
    volumes:
      - ../frontend:/app
      - /app/node_modules
    command: npm run dev

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.96.0
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "8888:8888"  # Metrics
      - "8889:8889"  # Prometheus metrics
    depends_on:
      - jaeger

  jaeger:
    image: jaegertracing/all-in-one:1.53
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    ports:
      - "16686:16686"  # Jaeger UI
      - "14268:14268"  # HTTP collector
      - "14250:14250"  # gRPC collector
EOF

# Update docker/compose.prod.yml
cat >> docker/compose.prod.yml << 'EOF'

  frontend:
    build:
      context: ../frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
    environment:
      - VITE_API_URL=http://delineate-app:3000
      - VITE_OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
    depends_on:
      - delineate-app
      - otel-collector

  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.96.0
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"
      - "4318:4318"
    depends_on:
      - jaeger

  jaeger:
    image: jaegertracing/all-in-one:1.53
    environment:
      - COLLECTOR_OTLP_ENABLED=true
      - LOG_LEVEL=debug
    ports:
      - "16686:16686"
    volumes:
      - jaeger_data:/tmp
    restart: unless-stopped

volumes:
  jaeger_data:
EOF

# 25. Create OpenTelemetry collector config
cat > docker/otel-collector-config.yaml << 'EOF'
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024

exporters:
  debug:
    verbosity: detailed
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger, debug]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
EOF

# 26. Create README for frontend
cat > frontend/README.md << 'EOF'
# Delineate Observability Dashboard

A React-based dashboard for monitoring the Delineate download service with full observability integration.

## Features

- **Real-time monitoring**: Health checks, download job status, error tracking
- **Sentry integration**: Error tracking with user feedback and replay
- **OpenTelemetry**: Distributed tracing with Jaeger visualization
- **Performance metrics**: Response times, success rates, and error rates
- **Trace correlation**: End-to-end traceability from frontend to backend

## Prerequisites

- Node.js 18+
- Docker and Docker Compose
- Sentry account (for error tracking)
- Delineate API running on port 3000

## Setup

### 1. Environment Configuration

Copy the example environment file:

```bash
cp .env.example .env.local

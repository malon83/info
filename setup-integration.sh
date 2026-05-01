#!/bin/bash
# setup-integration.sh — PersonaOS + EAFIT Challenge Backend (100% Compatible)
# Basado en: https://eafit-challenge-back.onrender.com/api-docs/#/
# Ejecución: curl -sSL https://raw.githubusercontent.com/malon83/personaos-frontend/main/scripts/setup-integration.sh | bash


set -e  # Salir ante errores

# =============================================================================
# CONFIGURACIÓN DE COLORES Y LOGGING
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[ℹ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_step()    { echo -e "\n${CYAN}➜ $1${NC}"; }

# =============================================================================
# 1. VALIDACIONES PREVIAS DEL ENTORNO
# =============================================================================
log_step "Validando entorno de desarrollo..."

# Verificar Node.js >= 18
if ! command -v node &> /dev/null; then
  log_error "Node.js no está instalado. Instálalo desde https://nodejs.org"
  exit 1
fi

NODE_MAJOR=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then
  log_error "Node.js >= 18 requerido. Versión actual: $(node -v)"
  exit 1
fi
log_success "Node.js $(node -v) detectado ✓"

# Verificar package manager
if command -v pnpm &> /dev/null; then
  PKG_MGR="pnpm"
  PKG_INSTALL="pnpm install"
  PKG_RUN="pnpm run"
elif command -v npm &> /dev/null; then
  PKG_MGR="npm"
  PKG_INSTALL="npm install"
  PKG_RUN="npm run"
else
  log_error "npm o pnpm requeridos"
  exit 1
fi
log_info "Package manager: $PKG_MGR"

# Verificar git
if ! command -v git &> /dev/null; then
  log_warn "git no detectado (recomendado para control de versiones)"
fi

# =============================================================================
# 2. CONFIGURACIÓN INTERACTIVA (con valores por defecto del reto EAFIT)
# =============================================================================
log_step "Configuración de integración EAFIT Challenge"

# Valores oficiales del reto (pueden personalizarse)
DEFAULT_API_URL="https://eafit-challenge-back.onrender.com/api/v1"
DEFAULT_LANDING_URL="https://landing-l4tx.onrender.com"
DEFAULT_PROJECT_NAME="personaos-frontend"
DEFAULT_HOLOGRAM_URL="https://hologram.zone"
DEFAULT_VERANA_NETWORK="testnet.verana.network"

echo -e "${BLUE}┌─────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔗 Configuración Backend EAFIT         │${NC}"
echo -e "${BLUE}└─────────────────────────────────────────┘${NC}"

read -p "📡 API Backend URL [$DEFAULT_API_URL]: " API_URL
API_URL="${API_URL:-$DEFAULT_API_URL}"

read -p "🏠 Landing OAuth URL [$DEFAULT_LANDING_URL]: " LANDING_URL
LANDING_URL="${LANDING_URL:-$DEFAULT_LANDING_URL}"

read -p "📦 Nombre del proyecto frontend [$DEFAULT_PROJECT_NAME]: " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}"

read -p "⬡ Hologram URL [$DEFAULT_HOLOGRAM_URL]: " HOLOGRAM_URL
HOLOGRAM_URL="${HOLOGRAM_URL:-$DEFAULT_HOLOGRAM_URL}"

read -p "🌐 Verana Network [$DEFAULT_VERANA_NETWORK]: " VERANA_NETWORK
VERANA_NETWORK="${VERANA_NETWORK:-$DEFAULT_VERANA_NETWORK}"

read -p "🔑 Credential Definition ID [dejar vacío para usar default]: " CRED_DEF_ID
CRED_DEF_ID="${CRED_DEF_ID:-did:webvh:QmPZBr...eafit.testnet.verana.network}"

# Dominio de producción (opcional)
read -p "🌍 Dominio de producción (ej: personaos.verana.network) [opcional]: " PROD_DOMAIN

# =============================================================================
# 3. CREAR ESTRUCTURA BASE DEL PROYECTO
# =============================================================================
log_step "Creando estructura del proyecto: $PROJECT_NAME"

mkdir -p "$PROJECT_NAME" && cd "$PROJECT_NAME"

# Crear .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnpm-store/

# Environment
.env*.local
!.env.example

# Build
dist/
.output/
.cache/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Testing
coverage/
.playwright/
test-results/

# Generated files
src/components/generated/
EOF
log_success ".gitignore creado"

# Crear package.json con dependencias exactas
cat > package.json << 'EOF'
{
  "name": "personaos-frontend",
  "type": "module",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "astro": "astro",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "typecheck": "astro check",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "setup": "node scripts/first-run.js"
  },
  "dependencies": {
    "@astrojs/react": "^3.6.2",
    "@astrojs/node": "^8.3.4",
    "astro": "^4.16.10",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "axios": "^1.7.9",
    "zustand": "^4.5.5",
    "js-cookie": "^3.0.5",
    "file-saver": "^2.0.5",
    "js-yaml": "^4.1.0",
    "react-router-dom": "^6.28.0",
    "lucide-react": "^0.468.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.5.5"
  },
  "devDependencies": {
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "@types/js-cookie": "^3.0.6",
    "@types/file-saver": "^2.0.7",
    "@types/js-yaml": "^4.0.9",
    "@astrojs/check": "^0.9.4",
    "typescript": "^5.7.2",
    "eslint": "^8.57.1",
    "eslint-plugin-astro": "^1.3.1",
    "eslint-plugin-react": "^7.37.2",
    "vitest": "^1.6.0",
    "@vitest/ui": "^1.6.0",
    "@playwright/test": "^1.49.0",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.49",
    "tailwindcss": "^3.4.16"
  }
}
EOF
log_success "package.json creado con dependencias"

# Crear tsconfig.json (opcional pero recomendado)
cat > tsconfig.json << 'EOF'
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "react",
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@components/*": ["src/components/*"],
      "@hooks/*": ["src/hooks/*"],
      "@lib/*": ["src/lib/*"],
      "@pages/*": ["src/pages/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# =============================================================================
# 4. CONFIGURACIÓN DE ASTRO + PROXY API
# =============================================================================
log_step "Configurando Astro con proxy al backend EAFIT"

cat > astro.config.mjs << EOF
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import node from '@astrojs/node';

export default defineConfig({
  integrations: [react()],
  output: 'server',
  adapter: node({
    mode: 'middleware'
  }),
  server: {
    port: 4321,
    host: true,
    allowedHosts: ['localhost', '127.0.0.1', '0.0.0.0']
  },
  vite: {
    server: {
      proxy: {
        '/api': {
          target: '${API_URL}',
          changeOrigin: true,
          secure: false,
          rewrite: (path) => path.replace(/^\\/api\\/v1/, '/api/v1'),
          configure: (proxy, options) => {
            proxy.on('error', (err, req, res) => {
              console.log('proxy error', err);
            });
            proxy.on('proxyReq', (proxyReq, req, res) => {
              console.log('Sending Request to:', req.method, req.url);
            });
          }
        }
      }
    },
    resolve: {
      alias: {
        '@': '/src',
        '@components': '/src/components',
        '@hooks': '/src/hooks',
        '@lib': '/src/lib',
        '@pages': '/src/pages'
      }
    }
  }
});
EOF
log_success "astro.config.mjs configurado con proxy API"

# =============================================================================
# 5. VARIABLES DE ENTORNO (.env.example)
# =============================================================================
log_step "Generando configuración de entorno"

cat > .env.example << EOF
# ========================================
# 🔗 API Backend EAFIT Challenge
# ========================================
# URL base del backend (Swagger: /api-docs)
PUBLIC_API_URL=${API_URL}

# ========================================
# 🔐 Autenticación OAuth Google
# ========================================
# Landing page donde los usuarios inician sesión
PUBLIC_LANDING_URL=${LANDING_URL}
# Ruta de callback en el frontend
PUBLIC_CALLBACK_URL=/auth/callback

# ========================================
# ⬡ Hologram / Verana Ecosystem
# ========================================
PUBLIC_HOLOGRAM_URL=${HOLOGRAM_URL}
PUBLIC_VERANA_NETWORK=${VERANA_NETWORK}
PUBLIC_CRED_DEF_ID=${CRED_DEF_ID}
PUBLIC_ORG_VS_URL=organization.eafit.testnet.verana.network

# ========================================
# 🧪 Desarrollo (solo local)
# ========================================
NODE_ENV=development
ENABLE_MOCK_API=false

# ========================================
# 🚀 Producción (configurar en Vercel/Render)
# ========================================
# COOKIE_DOMAIN=.verana.network
# SESSION_MAX_AGE=604800
EOF

# Copiar a .env.local si no existe
[ ! -f .env.local ] && cp .env.example .env.local
log_success ".env.example y .env.local creados"

# =============================================================================
# 6. ARCHIVO CORE: api-client.js (100% Compatible con Swagger)
# =============================================================================
log_step "Generando cliente API centralizado (compatible con /api-docs)"

mkdir -p src/lib

cat > src/lib/api-client.js << 'ENDOFFILE'
/**
 * Cliente API centralizado para PersonaOS
 * 100% compatible con backend EAFIT Challenge
 * Swagger: https://eafit-challenge-back.onrender.com/api-docs
 */

const API_BASE = import.meta.env.PUBLIC_API_URL || 'https://eafit-challenge-back.onrender.com/api/v1';

class ApiClient {
  constructor() {
    this.baseURL = API_BASE;
    this.defaultHeaders = {
      'Content-Type': 'application/json'
    };
  }

  /**
   * Request genérico con manejo de errores y tokens
   */
  async request(endpoint, options = {}) {
    const { token, skipAuth, ...fetchOptions } = options;
    
    const headers = {
      ...this.defaultHeaders,
      ...(token && !skipAuth && { Authorization: `Bearer ${token}` }),
      ...fetchOptions.headers
    };

    const url = endpoint.startsWith('http') ? endpoint : `${this.baseURL}${endpoint}`;

    try {
      const response = await fetch(url, {
        ...fetchOptions,
        headers,
        credentials: 'include',
        cache: 'no-store'
      });

      // Manejar errores HTTP
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        
        if (response.status === 401) {
          // Token inválido o expirado
          if (typeof window !== 'undefined') {
            window.dispatchEvent(new CustomEvent('auth:unauthorized', { 
              detail: { message: errorData.message || 'Sesión expirada' } 
            }));
          }
          throw new Error('UNAUTHORIZED');
        }
        
        if (response.status === 403) {
          throw new Error(errorData.message || 'Acceso denegado');
        }
        
        if (response.status === 404) {
          throw new Error(errorData.message || 'Recurso no encontrado');
        }
        
        if (response.status === 409) {
          throw new Error(errorData.message || 'Conflicto de datos');
        }
        
        throw new Error(errorData.message || `HTTP ${response.status}: ${response.statusText}`);
      }

      // Parsear respuesta según Content-Type
      const contentType = response.headers.get('content-type');
      
      if (contentType?.includes('application/json')) {
        const data = await response.json();
        return { data, headers: response.headers, status: response.status };
      }
      
      if (contentType?.includes('text/yaml') || contentType?.includes('application/x-yaml')) {
        const text = await response.text();
        return { data: text, headers: response.headers, status: response.status };
      }
      
      // Fallback: texto plano
      const text = await response.text();
      return { data: text, headers: response.headers, status: response.status };

    } catch (error) {
      if (error.message === 'Failed to fetch') {
        throw new Error('Error de conexión con el backend. Verifica tu conexión a internet.');
      }
      throw error;
    }
  }

  // ==================== MÉTODOS HTTP ====================
  get(endpoint, options = {}) {
    return this.request(endpoint, { ...options, method: 'GET' });
  }

  post(endpoint, body, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'POST',
      body: JSON.stringify(body)
    });
  }

  put(endpoint, body, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'PUT',
      body: JSON.stringify(body)
    });
  }

  patch(endpoint, body, options = {}) {
    return this.request(endpoint, {
      ...options,
      method: 'PATCH',
      body: JSON.stringify(body)
    });
  }

  delete(endpoint, options = {}) {
    return this.request(endpoint, { ...options, method: 'DELETE' });
  }

  // ==================== ENDPOINTS: AUTH ====================
  auth = {
    /**
     * GET /auth/google - Iniciar OAuth con Google
     * @returns {string} URL de redirección
     */
    googleLogin: (redirectUrl) => {
      const callback = encodeURIComponent(redirectUrl || window.location.origin + '/auth/callback');
      return `${API_BASE}/auth/google?redirect=${callback}`;
    },

    /**
     * GET /auth/me - Obtener usuario autenticado
     * @param {string} token - JWT token
     * @returns {Promise<AuthenticatedUser>}
     */
    me: (token) => this.get('/auth/me', { token }),

    /**
     * POST /auth/logout - Cerrar sesión
     * @param {string} token - JWT token
     */
    logout: (token) => this.post('/auth/logout', {}, { token })
  };

  // ==================== ENDPOINTS: BOTS ====================
  bots = {
    /**
     * GET /bots - Listar bots del usuario autenticado
     * @param {string} token - JWT token
     */
    list: (token) => this.get('/bots', { token }),

    /**
     * GET /bots/published - Listar bots públicos (sin auth)
     */
    published: () => this.get('/bots/published'),

    /**
     * POST /bots - Crear nuevo bot
     * @param {BotCreateRequest} data
     * @param {string} token - JWT token
     */
    create: (data, token) => this.post('/bots', data, { token }),

    /**
     * GET /bots/:id - Obtener bot por ID
     * @param {string} id
     * @param {string} token - JWT token
     */
    get: (id, token) => this.get(`/bots/${id}`, { token }),

    /**
     * PUT /bots/:id - Actualizar bot completo
     * @param {string} id
     * @param {BotUpdateRequest} data
     * @param {string} token - JWT token
     */
    update: (id, data, token) => this.put(`/bots/${id}`, data, { token }),

    /**
     * PATCH /bots/:id - Actualizar campos parciales
     * @param {string} id
     * @param {Partial<Bot>} data
     * @param {string} token - JWT token
     */
    patch: (id, data, token) => this.patch(`/bots/${id}`, data, { token }),

    /**
     * DELETE /bots/:id - Eliminar bot
     * @param {string} id
     * @param {string} token - JWT token
     */
    delete: (id, token) => this.delete(`/bots/${id}`, { token }),

    /**
     * PATCH /bots/:id/publish - Publicar bot en Hologram
     * @param {string} id
     * @param {string} service_slug - Slug único del servicio
     * @param {string} agentPublicUrl - URL pública del VS Agent (ngrok/k8s)
     * @param {string} token - JWT token
     */
    publish: (id, service_slug, agentPublicUrl, token) => 
      this.patch(`/bots/${id}/publish`, { 
        service_slug, 
        agent_public_url: agentPublicUrl 
      }, { token }),

    /**
     * PATCH /bots/:id/unpublish - Despublicar bot
     * @param {string} id
     * @param {string} token - JWT token
     */
    unpublish: (id, token) => this.patch(`/bots/${id}/unpublish`, {}, { token }),

    /**
     * GET /bots/:id/history - Historial de publicaciones
     * @param {string} id
     * @param {string} token - JWT token
     */
    history: (id, token) => this.get(`/bots/${id}/history`, { token }),

    /**
     * POST /bots/:id/chat - Enviar mensaje al bot (testing directo)
     * @param {string} id
     * @param {string} message
     * @param {string} token - JWT token
     */
    chat: (id, message, token) => 
      this.post(`/bots/${id}/chat`, { message }, { token }),

    // === Archivos adjuntos ===
    files: {
      list: (botId, token) => this.get(`/bots/${botId}/files`, { token }),
      
      upload: (botId, formData, token) => 
        this.request(`/bots/${botId}/files`, {
          method: 'POST',
          token,
          headers: { 'Content-Type': 'multipart/form-data' },
          body: formData
        }),
      
      delete: (botId, fileId, token) => 
        this.delete(`/bots/${botId}/files/${fileId}`, { token })
    }
  };

  // ==================== ENDPOINTS: LLM ====================
  llm = {
    /**
     * GET /llm-providers - Listar proveedores LLM disponibles
     */
    providers: () => this.get('/llm-providers'),

    /**
     * GET /llm-models - Listar modelos LLM (con filtro opcional)
     * @param {string} providerId - Filtrar por proveedor
     */
    models: (providerId) => {
      const query = providerId ? `?provider_id=${providerId}` : '';
      return this.get(`/llm-models${query}`);
    }
  };

  // ==================== ENDPOINTS: MCP SERVICES ====================
  mcp = {
    /**
     * GET /mcp-services - Listar servicios MCP disponibles
     */
    list: () => this.get('/mcp-services'),

    /**
     * GET /mcp-services/:id - Obtener servicio por ID
     */
    get: (id) => this.get(`/mcp-services/${id}`)
  };

  // ==================== ENDPOINTS: CATEGORÍAS ====================
  categories = {
    /**
     * GET /service-categories - Listar categorías de servicios
     */
    list: () => this.get('/service-categories')
  };

  // ==================== UTILIDADES ====================
  /**
   * Verificar salud del backend
   */
  health: () => this.get('/health', { skipAuth: true }),

  /**
   * Obtener versión de la API
   */
  version: () => this.get('/version', { skipAuth: true })
}

// Exportar instancia singleton
export default new ApiClient();

// ==================== TIPOS JSDoc ====================
/**
 * @typedef {Object} AuthenticatedUser
 * @property {string} id
 * @property {string} email
 * @property {string} name
 * @property {string} google_id
 * @property {string} [avatar_url]
 * @property {string} created_at
 */

/**
 * @typedef {Object} BotCreateRequest
 * @property {string} name
 * @property {string} [profession]
 * @property {string} [description]
 * @property {string} [avatar]
 * @property {string} [category_id]
 * @property {string} service_slug
 * @property {string} model_provider_id
 * @property {string} llm_model_id
 * @property {string} system_prompt
 * @property {string} [welcome_message]
 * @property {'professional'|'friendly'|'technical'|'empathetic'} [tone]
 * @property {string[]} [capabilities]
 * @property {string[]} mcp_service_ids
 */

/**
 * @typedef {Object} Bot
 * @property {string} id
 * @property {string} name
 * @property {string} profession
 * @property {string} description
 * @property {string} avatar
 * @property {string} user_id
 * @property {string} [category_id]
 * @property {string} service_slug
 * @property {boolean} is_published
 * @property {string|null} hologram_url
 * @property {string|null} qr_code
 * @property {string} created_at
 * @property {string} updated_at
 */
ENDOFFILE
log_success "api-client.js generado (100% compatible con Swagger)"

# =============================================================================
# 7. HOOK: useAuth.js (Gestión de Autenticación)
# =============================================================================
log_step "Generando hook de autenticación useAuth.js"

mkdir -p src/hooks

cat > src/hooks/useAuth.js << 'ENDOFFILE'
/**
 * Hook de autenticación con Zustand + js-cookie
 * Gestiona sesión, token JWT y usuario autenticado
 */
import { create } from 'zustand';
import Cookies from 'js-cookie';
import apiClient from '../lib/api-client';

const TOKEN_COOKIE_NAME = 'session_token';
const TOKEN_EXPIRY_DAYS = 7;

export const useAuth = create((set, get) => ({
  // Estado
  user: null,
  token: null,
  loading: true,
  error: null,

  // Inicializar: verificar token existente
  init: async () => {
    const token = Cookies.get(TOKEN_COOKIE_NAME);
    
    if (!token) {
      set({ loading: false, token: null, user: null });
      return null;
    }

    set({ token, loading: true });

    try {
      const {  user } = await apiClient.auth.me(token);
      set({ user, loading: false, error: null });
      return user;
    } catch (error) {
      // Token inválido o expirado
      Cookies.remove(TOKEN_COOKIE_NAME);
      set({ user: null, token: null, loading: false, error: error.message });
      
      // Notificar a la UI para redirigir
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent('auth:expired'));
      }
      return null;
    }
  },

  // Verificar sesión activa (sin cargar estado global)
  checkSession: async () => {
    const token = get().token || Cookies.get(TOKEN_COOKIE_NAME);
    if (!token) return false;

    try {
      await apiClient.auth.me(token);
      return true;
    } catch {
      return false;
    }
  },

  // Guardar token tras login exitoso
  setToken: (token) => {
    Cookies.set(TOKEN_COOKIE_NAME, token, {
      expires: TOKEN_EXPIRY_DAYS,
      path: '/',
      secure: import.meta.env.PROD,
      sameSite: 'lax'
    });
    set({ token, error: null });
  },

  // Logout: limpiar sesión y notificar backend
  logout: async () => {
    const { token } = get();
    
    // Notificar backend si hay token válido
    if (token) {
      await apiClient.auth.logout(token).catch(() => {});
    }

    // Limpiar estado local
    Cookies.remove(TOKEN_COOKIE_NAME);
    set({ user: null, token: null, error: null });

    // Redirigir a landing
    if (typeof window !== 'undefined') {
      window.location.href = import.meta.env.PUBLIC_LANDING_URL;
    }
  },

  // Actualizar datos de usuario (tras edición de perfil)
  updateUser: (userData) => {
    set(state => ({
      user: { ...state.user, ...userData }
    }));
  },

  // Limpiar error
  clearError: () => set({ error: null })
}));

// Listener global para eventos de auth
if (typeof window !== 'undefined') {
  window.addEventListener('auth:unauthorized', (e) => {
    console.warn('Auth event: unauthorized', e.detail);
    useAuth.getState().logout();
  });

  window.addEventListener('auth:expired', () => {
    console.warn('Auth event: token expired');
    useAuth.getState().logout();
  });
}
ENDOFFILE
log_success "useAuth.js generado"

# =============================================================================
# 8. MIDDLEWARE: auth.js (Protección de Rutas Astro)
# =============================================================================
log_step "Generando middleware de protección de rutas"

mkdir -p src/middleware

cat > src/middleware/auth.js << 'ENDOFFILE'
/**
 * Middleware de autenticación para páginas Astro
 * Protege rutas que requieren usuario autenticado
 */

/**
 * Verificar autenticación y redirigir si no hay sesión
 * @param {Object} context - Contexto de Astro ({ cookies, redirect, request })
 * @returns {Promise<AuthenticatedUser|null>} Usuario o null si no autenticado
 */
export async function requireAuth({ cookies, redirect, request }) {
  const token = cookies.get('session_token')?.value;
  const landingUrl = import.meta.env.PUBLIC_LANDING_URL || 'https://landing-l4tx.onrender.com';
  
  // Sin token → redirigir a landing
  if (!token) {
    const currentPath = new URL(request.url).pathname;
    const redirectParam = encodeURIComponent(currentPath);
    return redirect(`${landingUrl}?next=${redirectParam}`, 302);
  }

  // Validar token con backend
  try {
    const response = await fetch(
      `${import.meta.env.PUBLIC_API_URL}/auth/me`,
      {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        cache: 'no-store'
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const user = await response.json();
    return user;

  } catch (error) {
    console.error('Auth validation failed:', error);
    
    // Token inválido → limpiar cookie y redirigir
    cookies.delete('session_token', { path: '/' });
    
    const currentPath = new URL(request.url).pathname;
    const redirectParam = encodeURIComponent(currentPath);
    return redirect(`${landingUrl}?error=auth_failed&next=${redirectParam}`, 302);
  }
}

/**
 * Middleware opcional: solo redirige si NO hay sesión
 * Útil para páginas públicas como /auth/callback
 */
export function redirectIfAuthenticated({ cookies, redirect }) {
  const token = cookies.get('session_token')?.value;
  
  if (token) {
    return redirect('/dashboard', 302);
  }
  
  return null;
}
ENDOFFILE
log_success "auth middleware generado"

# =============================================================================
# 9. PÁGINA: auth/callback.astro (Manejo de OAuth)
# =============================================================================
log_step "Generando página de callback OAuth"

mkdir -p src/pages/auth

cat > src/pages/auth/callback.astro << 'ENDOFFILE'
---
// src/pages/auth/callback.astro
// Maneja el callback de Google OAuth desde el backend EAFIT

import type { APIRoute } from 'astro';
import { redirect } from 'astro:middleware';

export const prerender = false;

export const GET: APIRoute = async ({ request, cookies, redirect }) => {
  const url = new URL(request.url);
  const token = url.searchParams.get('token');
  const error = url.searchParams.get('error');
  const next = url.searchParams.get('next') || '/dashboard';
  
  const landingUrl = import.meta.env.PUBLIC_LANDING_URL || 'https://landing-l4tx.onrender.com';

  // === Caso 1: Error en OAuth ===
  if (error) {
    console.error('OAuth callback error:', error);
    
    return new Response(null, {
      status: 302,
      headers: { 
        Location: `${landingUrl}?error=${encodeURIComponent(error)}` 
      }
    });
  }

  // === Caso 2: Token recibido → guardar sesión ===
  if (token) {
    // Validar formato básico del JWT
    const tokenParts = token.split('.');
    if (tokenParts.length !== 3) {
      console.error('Invalid JWT token format');
      return new Response('Invalid token', { status: 400 });
    }

    // Guardar token en cookie segura
    cookies.set('session_token', token, {
      path: '/',
      httpOnly: true,              // No accesible vía JavaScript
      secure: import.meta.env.PROD, // Solo HTTPS en producción
      sameSite: 'lax',             // Protección CSRF
      maxAge: 60 * 60 * 24 * 7     // 7 días
    });

    console.log('✓ Auth successful, redirecting to:', next);

    // Redirigir a la página solicitada o dashboard
    return new Response(null, {
      status: 302,
      headers: { Location: next }
    });
  }

  // === Caso 3: Sin token ni error → fallback ===
  console.warn('Callback received without token or error');
  
  return new Response('Authentication failed: no token received', { 
    status: 401,
    headers: { 'Content-Type': 'text/plain' }
  });
};
---
<!-- Página de carga mientras se procesa el callback -->
<!doctype html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Autenticando... ◈ PersonaOS</title>
  <style>
    body {
      margin: 0;
      font-family: system-ui, -apple-system, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      color: white;
    }
    .container {
      text-align: center;
      padding: 2rem;
    }
    .spinner {
      width: 48px;
      height: 48px;
      border: 4px solid rgba(255,255,255,0.3);
      border-top-color: white;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 1rem;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    p { opacity: 0.9; }
  </style>
</head>
<body>
  <div class="container">
    <div class="spinner"></div>
    <h1>◈ Verificando identidad...</h1>
    <p>Redirigiendo a PersonaOS</p>
  </div>
  <script>
    // Fallback: si el redirect falla, intentar en 3s
    setTimeout(() => {
      const params = new URLSearchParams(window.location.search);
      const next = params.get('next') || '/dashboard';
      if (window.location.pathname.includes('/auth/callback')) {
        window.location.href = next;
      }
    }, 3000);
  </script>
</body>
</html>
ENDOFFILE
log_success "auth/callback.astro generado"

# =============================================================================
# 10. COMPONENTE: GoogleLoginButton.jsx
# =============================================================================
log_step "Generando componente de login con Google"

mkdir -p src/components/auth

cat > src/components/auth/GoogleLoginButton.jsx << 'ENDOFFILE'
/**
 * Botón de inicio de sesión con Google OAuth
 * Redirige al backend para iniciar flujo de autenticación
 */
import { useState } from 'react';
import { LogIn, Loader2 } from 'lucide-react';

export default function GoogleLoginButton({ 
  redirectUrl, 
  variant = 'primary',
  className = '',
  disabled = false 
}) {
  const [loading, setLoading] = useState(false);

  const handleLogin = () => {
    if (loading || disabled) return;
    
    setLoading(true);
    
    try {
      const apiURL = import.meta.env.PUBLIC_API_URL;
      const landingURL = import.meta.env.PUBLIC_LANDING_URL;
      
      // Construir URL de callback para este frontend
      const callbackBase = window.location.origin;
      const nextPath = redirectUrl || '/dashboard';
      const callback = encodeURIComponent(`${callbackBase}/auth/callback?next=${encodeURIComponent(nextPath)}`);
      
      // Redirigir al endpoint de auth del backend
      const authUrl = `${apiURL}/auth/google?redirect=${callback}`;
      
      console.log('Redirecting to Google OAuth:', authUrl);
      window.location.href = authUrl;
      
    } catch (error) {
      console.error('Login redirect failed:', error);
      setLoading(false);
      alert('Error al iniciar sesión. Intenta nuevamente.');
    }
  };

  const baseClasses = 'flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg font-medium transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed';
  
  const variants = {
    primary: 'bg-white text-gray-900 hover:bg-gray-100 focus:ring-gray-500 shadow-sm',
    outline: 'border-2 border-white/30 text-white hover:bg-white/10 focus:ring-white',
    ghost: 'text-gray-700 hover:bg-gray-100 focus:ring-gray-500'
  };

  return (
    <button
      type="button"
      onClick={handleLogin}
      disabled={loading || disabled}
      className={`${baseClasses} ${variants[variant]} ${className}`}
      aria-label="Iniciar sesión con Google"
    >
      {loading ? (
        <>
          <Loader2 className="w-4 h-4 animate-spin" />
          <span>Conectando...</span>
        </>
      ) : (
        <>
          {/* Google "G" icon SVG */}
          <svg className="w-4 h-4" viewBox="0 0 24 24">
            <path
              fill="#4285F4"
              d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
            />
            <path
              fill="#34A853"
              d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
            />
            <path
              fill="#FBBC05"
              d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
            />
            <path
              fill="#EA4335"
              d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
            />
          </svg>
          <span>Iniciar con Google</span>
        </>
      )}
    </button>
  );
}
ENDOFFILE
log_success "GoogleLoginButton.jsx generado"

# =============================================================================
# 11. COMPONENTE: BotsList.jsx (Dashboard Principal)
# =============================================================================
log_step "Generando componente de listado de bots"

mkdir -p src/components/dashboard

cat > src/components/dashboard/BotsList.jsx << 'ENDOFFILE'
/**
 * Listado de bots del usuario con acciones CRUD
 * Conectado al backend vía useBots hook
 */
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bot, Plus, Settings, Trash2, ExternalLink, Loader2, AlertCircle } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import apiClient from '../../lib/api-client';

export default function BotsList() {
  const { token, user } = useAuth();
  const navigate = useNavigate();
  
  const [bots, setBots] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [deletingId, setDeletingId] = useState(null);

  const fetchBots = async () => {
    if (!token) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const {  fetchedBots } = await apiClient.bots.list(token);
      setBots(Array.isArray(fetchedBots) ? fetchedBots : []);
    } catch (err) {
      console.error('Failed to fetch bots:', err);
      setError(err.message === 'UNAUTHORIZED' 
        ? 'Sesión expirada. Por favor inicia sesión nuevamente.'
        : 'Error al cargar tus bots. Intenta recargar la página.');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (botId, botName) => {
    if (!confirm(`¿Estás seguro de eliminar "${botName}"? Esta acción no se puede deshacer.`)) {
      return;
    }

    setDeletingId(botId);
    
    try {
      await apiClient.bots.delete(botId, token);
      setBots(prev => prev.filter(b => b.id !== botId));
    } catch (err) {
      alert(`Error al eliminar: ${err.message}`);
    } finally {
      setDeletingId(null);
    }
  };

  const handleCreate = () => {
    navigate('/bot/new');
  };

  const handleEdit = (bot) => {
    navigate(`/bot/${bot.id}`);
  };

  useEffect(() => {
    fetchBots();
  }, [token]);

  // Estado: Cargando
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-12">
        <Loader2 className="w-8 h-8 animate-spin text-purple-500 mb-4" />
        <p className="text-gray-600">Cargando tus agentes...</p>
      </div>
    );
  }

  // Estado: Error
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mb-4" />
        <p className="text-red-600 font-medium mb-2">{error}</p>
        <button 
          onClick={fetchBots}
          className="text-purple-600 hover:text-purple-700 font-medium"
        >
          Reintentar
        </button>
      </div>
    );
  }

  // Estado: Vacío
  if (bots.length === 0) {
    return (
      <div className="text-center py-12">
        <Bot className="w-16 h-16 text-gray-300 mx-auto mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 mb-2">
          Aún no tienes agentes creados
        </h3>
        <p className="text-gray-600 mb-6">
          Crea tu primer Persona AI Agent y conéctalo a Hologram Network
        </p>
        <button
          onClick={handleCreate}
          className="inline-flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Crear mi primer agente
        </button>
      </div>
    );
  }

  // Estado: Lista de bots
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-gray-900">
          Mis Agentes ({bots.length})
        </h2>
        <button
          onClick={handleCreate}
          className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-purple-600 hover:text-purple-700 hover:bg-purple-50 rounded-lg transition-colors"
        >
          <Plus className="w-4 h-4" />
          Nuevo
        </button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {bots.map(bot => (
          <div 
            key={bot.id}
            className="group relative bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md hover:border-purple-300 transition-all cursor-pointer"
            onClick={() => handleEdit(bot)}
          >
            {/* Badge de estado */}
            <div className="absolute top-3 right-3">
              {bot.is_published ? (
                <span className="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-green-700 bg-green-100 rounded-full">
                  <span className="w-1.5 h-1.5 bg-green-500 rounded-full" />
                  Publicado
                </span>
              ) : (
                <span className="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-gray-600 bg-gray-100 rounded-full">
                  Borrador
                </span>
              )}
            </div>

            {/* Avatar + Nombre */}
            <div className="flex items-start gap-3 mb-3">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-100 to-purple-200 flex items-center justify-center text-2xl">
                {bot.avatar || '🤖'}
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-gray-900 truncate">{bot.name}</h3>
                {bot.profession && (
                  <p className="text-sm text-gray-500">{bot.profession}</p>
                )}
              </div>
            </div>

            {/* Descripción */}
            {bot.description && (
              <p className="text-sm text-gray-600 line-clamp-2 mb-4">
                {bot.description}
              </p>
            )}

            {/* Acciones */}
            <div className="flex items-center gap-2 pt-3 border-t border-gray-100">
              <button
                onClick={(e) => { e.stopPropagation(); handleEdit(bot); }}
                className="flex-1 inline-flex items-center justify-center gap-1 px-3 py-1.5 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
              >
                <Settings className="w-3.5 h-3.5" />
                Configurar
              </button>
              
              {bot.is_published && bot.hologram_url && (
                <a
                  href={bot.hologram_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={(e) => e.stopPropagation()}
                  className="inline-flex items-center justify-center p-1.5 text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
                  title="Abrir en Hologram"
                >
                  <ExternalLink className="w-4 h-4" />
                </a>
              )}
              
              <button
                onClick={(e) => { e.stopPropagation(); handleDelete(bot.id, bot.name); }}
                disabled={deletingId === bot.id}
                className="inline-flex items-center justify-center p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50"
                title="Eliminar"
              >
                {deletingId === bot.id ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <Trash2 className="w-4 h-4" />
                )}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
ENDOFFILE
log_success "BotsList.jsx generado"

# =============================================================================
# 12. WIZARD: Componentes de los 5 pasos de creación de bot
# =============================================================================
log_step "Generando componentes del wizard de creación de bots"

mkdir -p src/components/builder

# --- Paso 1: BotForm.jsx (Identidad) ---
cat > src/components/builder/BotForm.jsx << 'ENDOFFILE'
/**
 * Paso 1: Identidad del Bot
 * Configura nombre, profesión, descripción y avatar
 */
import { useState } from 'react';
import { User, Briefcase, FileText, Smile } from 'lucide-react';

const AVATARS = ['👨‍🔧','👩‍💼','⚖️','🩺','🧠','💻','📊','🎯','🔬','🚀','🤖','🎓','💡','🔍','📈'];

export default function BotForm({ initialData, onNext, onBack }) {
  const [form, setForm] = useState({
    name: '',
    profession: '',
    description: '',
    avatar: '🤖',
    ...initialData
  });

  const [errors, setErrors] = useState({});

  const validate = () => {
    const newErrors = {};
    if (!form.name.trim()) newErrors.name = 'El nombre es requerido';
    if (form.name.length < 3) newErrors.name = 'Mínimo 3 caracteres';
    if (form.name.length > 50) newErrors.name = 'Máximo 50 caracteres';
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (validate()) {
      onNext({ ...form });
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Nombre */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
          <User className="w-4 h-4" />
          Nombre del Agente *
        </label>
        <input
          type="text"
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          placeholder="Ej: Asistente Legal IA"
          className={`w-full px-4 py-2.5 border rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none transition-colors ${
            errors.name ? 'border-red-500' : 'border-gray-300'
          }`}
        />
        {errors.name && <p className="mt-1 text-sm text-red-600">{errors.name}</p>}
        <p className="mt-1 text-xs text-gray-500">
          {form.name.length}/50 caracteres
        </p>
      </div>

      {/* Profesión */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
          <Briefcase className="w-4 h-4" />
          Profesión / Título
        </label>
        <input
          type="text"
          value={form.profession}
          onChange={(e) => setForm({ ...form, profession: e.target.value })}
          placeholder="Ej: Abogado, Médico, Coach, Developer..."
          className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none transition-colors"
        />
        <p className="mt-1 text-xs text-gray-500">
          Opcional. Define la especialidad de tu agente.
        </p>
      </div>

      {/* Descripción */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
          <FileText className="w-4 h-4" />
          Descripción
        </label>
        <textarea
          value={form.description}
          onChange={(e) => setForm({ ...form, description: e.target.value })}
          placeholder="Describe el propósito y capacidades principales de tu agente..."
          rows={3}
          className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none transition-colors resize-none"
        />
        <p className="mt-1 text-xs text-gray-500">
          {form.description.length}/200 caracteres recomendados
        </p>
      </div>

      {/* Avatar */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-3">
          <Smile className="w-4 h-4" />
          Avatar
        </label>
        <div className="flex flex-wrap gap-2">
          {AVATARS.map(emoji => (
            <button
              key={emoji}
              type="button"
              onClick={() => setForm({ ...form, avatar: emoji })}
              className={`w-10 h-10 text-xl rounded-lg border-2 transition-all ${
                form.avatar === emoji 
                  ? 'border-purple-500 bg-purple-50 scale-110' 
                  : 'border-gray-200 hover:border-purple-300 hover:bg-gray-50'
              }`}
              aria-label={`Seleccionar avatar ${emoji}`}
              aria-pressed={form.avatar === emoji}
            >
              {emoji}
            </button>
          ))}
        </div>
      </div>

      {/* Navegación */}
      <div className="flex items-center justify-between pt-4 border-t">
        {onBack && (
          <button
            type="button"
            onClick={onBack}
            className="px-4 py-2 text-gray-700 hover:text-gray-900 font-medium"
          >
            ← Atrás
          </button>
        )}
        <div className={onBack ? '' : 'ml-auto'}>
          <button
            type="submit"
            className="px-6 py-2.5 bg-purple-600 text-white rounded-lg hover:bg-purple-700 font-medium transition-colors"
          >
            Siguiente →
          </button>
        </div>
      </div>
    </form>
  );
}
ENDOFFILE

# --- Paso 2: ModelSelector.jsx ---
cat > src/components/builder/ModelSelector.jsx << 'ENDOFFILE'
/**
 * Paso 2: Selección de Modelo LLM
 * Conectado a /llm-providers y /llm-models del backend
 */
import { useEffect, useState } from 'react';
import { Brain, Key, Server, Loader2, AlertCircle } from 'lucide-react';
import apiClient from '../../lib/api-client';

export default function ModelSelector({ initialData, onNext, onBack, onModelChange }) {
  const [providers, setProviders] = useState([]);
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [selectedProvider, setSelectedProvider] = useState(initialData?.provider_id || '');
  const [selectedModel, setSelectedModel] = useState(initialData?.model || null);
  const [apiKey, setApiKey] = useState('');
  
  const [params, setParams] = useState({
    temperature: 0.7,
    max_tokens: 2048,
    language: 'es',
    ...initialData?.params
  });

  const fetchProviders = async () => {
    try {
      const {  data } = await apiClient.llm.providers();
      setProviders(Array.isArray(data) ? data : []);
      
      // Seleccionar primer proveedor por defecto
      if (data?.length > 0 && !selectedProvider) {
        setSelectedProvider(data[0].id);
        fetchModels(data[0].id);
      }
    } catch (err) {
      setError('Error al cargar proveedores LLM');
      console.error(err);
    }
  };

  const fetchModels = async (providerId) => {
    if (!providerId) return;
    
    setLoading(true);
    try {
      const {  data } = await apiClient.llm.models(providerId);
      setModels(Array.isArray(data) ? data : []);
      
      // Seleccionar modelo recomendado por defecto
      const recommended = data?.find(m => m.recommended);
      if (recommended && !selectedModel) {
        setSelectedModel(recommended);
      }
    } catch (err) {
      console.error('Error loading models:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProviders();
  }, []);

  useEffect(() => {
    if (selectedProvider) {
      fetchModels(selectedProvider);
    }
  }, [selectedProvider]);

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (!selectedModel) {
      alert('Por favor selecciona un modelo LLM');
      return;
    }

    // NOTA: La API Key se envía SOLO al backend, nunca se almacena en frontend
    const modelConfig = {
      provider_id: selectedProvider,
      model: selectedModel,
      params,
      // api_key se maneja server-side vía /users/me/keys
    };
    
    onModelChange?.(modelConfig);
    onNext(modelConfig);
  };

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mb-4" />
        <p className="text-red-600 font-medium mb-2">{error}</p>
        <button 
          onClick={fetchProviders}
          className="text-purple-600 hover:text-purple-700 font-medium"
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Proveedor LLM */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
          <Server className="w-4 h-4" />
          Proveedor LLM
        </label>
        <select
          value={selectedProvider}
          onChange={(e) => setSelectedProvider(e.target.value)}
          className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none bg-white"
        >
          <option value="">Seleccionar proveedor</option>
          {providers.map(provider => (
            <option key={provider.id} value={provider.id}>
              {provider.name} {provider.is_local && '(Local)'}
            </option>
          ))}
        </select>
      </div>

      {/* API Key (solo para proveedores cloud) */}
      {selectedProvider && providers.find(p => p.id === selectedProvider)?.api_key_env_var && (
        <div>
          <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
            <Key className="w-4 h-4" />
            API Key
          </label>
          <input
            type="password"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder={`sk-xxx...`}
            className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none font-mono text-sm"
          />
          <p className="mt-1 text-xs text-gray-500">
            Tu clave se cifrará y almacenará de forma segura en el backend.
          </p>
        </div>
      )}

      {/* Modelos disponibles */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-3">
          <Brain className="w-4 h-4" />
          Modelo
        </label>
        
        {loading ? (
          <div className="flex items-center gap-2 text-gray-500 py-3">
            <Loader2 className="w-4 h-4 animate-spin" />
            Cargando modelos...
          </div>
        ) : models.length === 0 ? (
          <p className="text-sm text-gray-500 italic">
            No hay modelos disponibles para este proveedor.
          </p>
        ) : (
          <div className="space-y-2 max-h-64 overflow-y-auto pr-2">
            {models.map(model => (
              <label
                key={model.id}
                className={`flex items-start gap-3 p-3 border rounded-lg cursor-pointer transition-all ${
                  selectedModel?.id === model.id
                    ? 'border-purple-500 bg-purple-50'
                    : 'border-gray-200 hover:border-purple-300'
                }`}
              >
                <input
                  type="radio"
                  name="model"
                  value={model.id}
                  checked={selectedModel?.id === model.id}
                  onChange={() => setSelectedModel(model)}
                  className="mt-1"
                />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-gray-900">{model.name}</span>
                    {model.recommended && (
                      <span className="px-1.5 py-0.5 text-xs font-medium text-purple-700 bg-purple-100 rounded">
                        Recomendado
                      </span>
                    )}
                  </div>
                  {model.description && (
                    <p className="text-sm text-gray-600 mt-1">{model.description}</p>
                  )}
                  {model.specs && (
                    <p className="text-xs text-gray-500 mt-1">{model.specs}</p>
                  )}
                </div>
              </label>
            ))}
          </div>
        )}
      </div>

      {/* Parámetros avanzados */}
      <details className="group">
        <summary className="flex items-center gap-2 text-sm font-medium text-gray-700 cursor-pointer list-none">
          ⚙️ Parámetros avanzados
          <span className="transition-transform group-open:rotate-180">▼</span>
        </summary>
        
        <div className="mt-4 space-y-4 pl-2 border-l-2 border-gray-200">
          {/* Temperatura */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              Temperatura: {params.temperature}
            </label>
            <input
              type="range"
              min="0"
              max="1"
              step="0.1"
              value={params.temperature}
              onChange={(e) => setParams({ ...params, temperature: parseFloat(e.target.value) })}
              className="w-full accent-purple-600"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>Preciso (0)</span>
              <span>Creativo (1)</span>
            </div>
          </div>

          {/* Max Tokens */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              Máximo de tokens
            </label>
            <select
              value={params.max_tokens}
              onChange={(e) => setParams({ ...params, max_tokens: parseInt(e.target.value) })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
            >
              <option value={512}>512 (Respuestas cortas)</option>
              <option value={1024}>1,024 (Estándar)</option>
              <option value={2048}>2,048 (Detalladas)</option>
              <option value={4096}>4,096 (Muy detalladas)</option>
            </select>
          </div>

          {/* Idioma */}
          <div>
            <label className="text-sm font-medium text-gray-700 mb-2 block">
              Idioma principal
            </label>
            <select
              value={params.language}
              onChange={(e) => setParams({ ...params, language: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
            >
              <option value="es">Español</option>
              <option value="en">English</option>
              <option value="pt">Português</option>
            </select>
          </div>
        </div>
      </details>

      {/* Navegación */}
      <div className="flex items-center justify-between pt-4 border-t">
        {onBack && (
          <button
            type="button"
            onClick={onBack}
            className="px-4 py-2 text-gray-700 hover:text-gray-900 font-medium"
          >
            ← Atrás
          </button>
        )}
        <div className={onBack ? '' : 'ml-auto'}>
          <button
            type="submit"
            disabled={!selectedModel || loading}
            className="px-6 py-2.5 bg-purple-600 text-white rounded-lg hover:bg-purple-700 font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Siguiente →
          </button>
        </div>
      </div>
    </form>
  );
}
ENDOFFILE

# --- Paso 3: PromptEditor.jsx ---
cat > src/components/builder/PromptEditor.jsx << 'ENDOFFILE'
/**
 * Paso 3: Configuración del Prompt del Sistema
 */
import { useState } from 'react';
import { MessageSquare, Sparkles, Volume2, Lightbulb } from 'lucide-react';

const TONES = [
  { id: 'professional', label: 'Profesional', icon: '💼', desc: 'Formal y preciso' },
  { id: 'friendly', label: 'Amigable', icon: '😊', desc: 'Cercano y empático' },
  { id: 'technical', label: 'Técnico', icon: '⚙️', desc: 'Especializado y detallado' },
  { id: 'empathetic', label: 'Empático', icon: '❤️', desc: 'Comprensivo y paciente' }
];

const CAPABILITIES = [
  { id: 'agendamiento', label: '📅 Agendamiento', desc: 'Gestionar citas y recordatorios' },
  { id: 'faq', label: '❓ FAQ', desc: 'Responder preguntas frecuentes' },
  { id: 'ventas', label: '💼 Ventas', desc: 'Asistir en procesos comerciales' },
  { id: 'soporte', label: '🛟 Soporte', desc: 'Resolver problemas técnicos' },
  { id: 'educacion', label: '🎓 Educación', desc: 'Enseñar y explicar conceptos' },
  { id: 'creatividad', label: '✨ Creatividad', desc: 'Generar contenido original' }
];

export default function PromptEditor({ initialData, onNext, onBack, onPromptChange }) {
  const [form, setForm] = useState({
    system_prompt: '',
    welcome_message: '¡Hola! 👋 Soy tu asistente. ¿En qué puedo ayudarte hoy?',
    tone: 'professional',
    capabilities: [],
    ...initialData
  });

  const [errors, setErrors] = useState({});

  const validate = () => {
    const newErrors = {};
    if (!form.system_prompt.trim()) {
      newErrors.system_prompt = 'El prompt del sistema es requerido';
    }
    if (form.system_prompt.length < 50) {
      newErrors.system_prompt = 'Mínimo 50 caracteres para un prompt efectivo';
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const toggleCapability = (id) => {
    setForm(prev => ({
      ...prev,
      capabilities: prev.capabilities.includes(id)
        ? prev.capabilities.filter(c => c !== id)
        : [...prev.capabilities, id]
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (validate()) {
      onPromptChange?.(form);
      onNext(form);
    }
  };

  const generatePromptSuggestion = () => {
    const { profession, name } = initialData || {};
    const suggestions = {
      professional: `Eres ${name || 'un asistente especializado'}${profession ? ` con experiencia en ${profession}` : ''}. Tu objetivo es proporcionar respuestas precisas, bien estructuradas y basadas en hechos. Mantén un tono profesional y evita especulaciones.`,
      friendly: `¡Hola! Soy ${name || 'tu asistente virtual'}${profession ? `, experto en ${profession}` : ''}. Estoy aquí para ayudarte de forma cercana y amigable. ¡No dudes en preguntarme lo que necesites!`,
      technical: `Soy un asistente técnico especializado${profession ? ` en ${profession}` : ''}. Proporciono respuestas detalladas con terminología precisa, referencias técnicas cuando sea relevante, y explicaciones paso a paso para problemas complejos.`,
      empathetic: `Soy ${name || 'tu compañero de conversación'}. Mi prioridad es escucharte con empatía, validar tus preocupaciones y ofrecerte apoyo comprensivo mientras te ayudo a encontrar soluciones.`
    };
    return suggestions[form.tone] || suggestions.professional;
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Prompt del Sistema */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
          <MessageSquare className="w-4 h-4" />
          System Prompt *
        </label>
        <textarea
          value={form.system_prompt}
          onChange={(e) => setForm({ ...form, system_prompt: e.target.value })}
          placeholder="Define la personalidad, reglas y comportamiento de tu agente..."
          rows={6}
          className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none font-mono text-sm resize-none ${
            errors.system_prompt ? 'border-red-500' : 'border-gray-300'
          }`}
        />
        {errors.system_prompt && (
          <p className="mt-1 text-sm text-red-600">{errors.system_prompt}</p>
        )}
        <div className="flex items-center justify-between mt-2">
          <p className="text-xs text-gray-500">
            {form.system_prompt.length} caracteres
          </p>
          <button
            type="button"
            onClick={() => setForm({ ...form, system_prompt: generatePromptSuggestion() })}
            className="text-xs text-purple-600 hover:text-purple-700 font-medium flex items-center gap-1"
          >
            <Sparkles className="w-3 h-3" />
            Generar sugerencia
          </button>
        </div>
      </div>

      {/* Mensaje de Bienvenida */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
          <Volume2 className="w-4 h-4" />
          Mensaje de Bienvenida
        </label>
        <input
          type="text"
          value={form.welcome_message}
          onChange={(e) => setForm({ ...form, welcome_message: e.target.value })}
          placeholder="Primer mensaje que verá el usuario..."
          className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 outline-none"
        />
        <p className="mt-1 text-xs text-gray-500">
          Aparece cuando el usuario inicia una nueva conversación.
        </p>
      </div>

      {/* Tono */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-3">
          <Lightbulb className="w-4 h-4" />
          Tono de Comunicación
        </label>
        <div className="grid grid-cols-2 gap-2">
          {TONES.map(tone => (
            <button
              key={tone.id}
              type="button"
              onClick={() => setForm({ ...form, tone: tone.id })}
              className={`flex items-start gap-2 p-3 border rounded-lg text-left transition-all ${
                form.tone === tone.id
                  ? 'border-purple-500 bg-purple-50'
                  : 'border-gray-200 hover:border-purple-300'
              }`}
            >
              <span className="text-xl">{tone.icon}</span>
              <div>
                <span className="font-medium text-sm text-gray-900">{tone.label}</span>
                <p className="text-xs text-gray-500">{tone.desc}</p>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Capacidades */}
      <div>
        <label className="text-sm font-medium text-gray-700 mb-3 block">
          Capacidades Principales
        </label>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
          {CAPABILITIES.map(cap => {
            const isActive = form.capabilities.includes(cap.id);
            return (
              <button
                key={cap.id}
                type="button"
                onClick={() => toggleCapability(cap.id)}
                className={`flex items-center gap-2 p-2.5 border rounded-lg text-left transition-all ${
                  isActive
                    ? 'border-purple-500 bg-purple-50 text-purple-900'
                    : 'border-gray-200 hover:border-purple-300 text-gray-700'
                }`}
              >
                <span className={`w-4 h-4 rounded border flex items-center justify-center ${
                  isActive ? 'bg-purple-600 border-purple-600' : 'border-gray-300'
                }`}>
                  {isActive && <span className="text-white text-xs">✓</span>}
                </span>
                <span className="text-sm">{cap.label}</span>
              </button>
            );
          })}
        </div>
        <p className="mt-2 text-xs text-gray-500">
          Selecciona las funciones principales de tu agente.
        </p>
      </div>

      {/* Navegación */}
      <div className="flex items-center justify-between pt-4 border-t">
        {onBack && (
          <button
            type="button"
            onClick={onBack}
            className="px-4 py-2 text-gray-700 hover:text-gray-900 font-medium"
          >
            ← Atrás
          </button>
        )}
        <div className={onBack ? '' : 'ml-auto'}>
          <button
            type="submit"
            className="px-6 py-2.5 bg-purple-600 text-white rounded-lg hover:bg-purple-700 font-medium transition-colors"
          >
            Siguiente →
          </button>
        </div>
      </div>
    </form>
  );
}
ENDOFFILE

# --- Paso 4: MCPToolsConfig.jsx ---
cat > src/components/builder/MCPToolsConfig.jsx << 'ENDOFFILE'
/**
 * Paso 4: Configuración de MCP Tools
 * Conectado a /mcp-services del backend
 */
import { useEffect, useState } from 'react';
import { Plug, Loader2, AlertCircle, ExternalLink } from 'lucide-react';
import apiClient from '../../lib/api-client';

export default function MCPToolsConfig({ initialData, onNext, onBack, onToolsChange }) {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const [selectedTools, setSelectedTools] = useState(
    initialData?.mcp_service_ids || []
  );

  const fetchServices = async () => {
    try {
      const {  data } = await apiClient.mcp.list();
      setServices(Array.isArray(data) ? data : []);
    } catch (err) {
      setError('Error al cargar herramientas MCP');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchServices();
  }, []);

  const toggleTool = (serviceId) => {
    setSelectedTools(prev => {
      const isSelected = prev.includes(serviceId);
      const updated = isSelected 
        ? prev.filter(id => id !== serviceId)
        : [...prev, serviceId];
      
      onToolsChange?.(updated);
      return updated;
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    // Mínimo 2 herramientas para publicar (validación del backend)
    if (selectedTools.length < 2) {
      alert('⚠️ Se requieren al menos 2 herramientas MCP para publicar tu agente en Hologram.');
      // Permitir continuar pero mostrar advertencia
    }
    
    onNext({ mcp_service_ids: selectedTools });
  };

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mb-4" />
        <p className="text-red-600 font-medium mb-2">{error}</p>
        <button 
          onClick={fetchServices}
          className="text-purple-600 hover:text-purple-700 font-medium"
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Header con requerimiento */}
      <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <div className="flex items-start gap-3">
          <Plug className="w-5 h-5 text-blue-600 mt-0.5" />
          <div>
            <h4 className="font-medium text-blue-900">Herramientas MCP</h4>
            <p className="text-sm text-blue-700 mt-1">
              Conecta servicios externos para ampliar las capacidades de tu agente.
              <strong> Mínimo 2 herramientas requeridas para publicar.</strong>
            </p>
          </div>
        </div>
      </div>

      {/* Lista de servicios */}
      <div>
        <label className="text-sm font-medium text-gray-700 mb-3 block">
          Servicios Disponibles
        </label>
        
        {loading ? (
          <div className="flex items-center gap-2 text-gray-500 py-4">
            <Loader2 className="w-4 h-4 animate-spin" />
            Cargando herramientas...
          </div>
        ) : services.length === 0 ? (
          <p className="text-sm text-gray-500 italic py-4">
            No hay herramientas MCP disponibles en este momento.
          </p>
        ) : (
          <div className="space-y-2">
            {services.map(service => {
              const isSelected = selectedTools.includes(service.id);
              return (
                <label
                  key={service.id}
                  className={`flex items-start gap-3 p-3 border rounded-lg cursor-pointer transition-all ${
                    isSelected
                      ? 'border-purple-500 bg-purple-50'
                      : 'border-gray-200 hover:border-purple-300'
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={isSelected}
                    onChange={() => toggleTool(service.id)}
                    className="mt-1"
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-gray-900">{service.name}</span>
                      {service.category && (
                        <span className="px-1.5 py-0.5 text-xs text-gray-600 bg-gray-100 rounded">
                          {service.category}
                        </span>
                      )}
                    </div>
                    {service.description && (
                      <p className="text-sm text-gray-600 mt-1">{service.description}</p>
                    )}
                    {service.config_schema && (
                      <details className="mt-2">
                        <summary className="text-xs text-purple-600 cursor-pointer">
                          Ver configuración requerida
                        </summary>
                        <pre className="mt-2 p-2 bg-gray-50 rounded text-xs overflow-x-auto">
                          {JSON.stringify(service.config_schema, null, 2)}
                        </pre>
                      </details>
                    )}
                  </div>
                  {service.docs_url && (
                    <a
                      href={service.docs_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      onClick={(e) => e.stopPropagation()}
                      className="p-1 text-gray-400 hover:text-purple-600"
                      title="Documentación"
                    >
                      <ExternalLink className="w-4 h-4" />
                    </a>
                  )}
                </label>
              );
            })}
          </div>
        )}
        
        {/* Contador de selección */}
        {selectedTools.length > 0 && (
          <p className={`mt-3 text-sm font-medium ${
            selectedTools.length >= 2 ? 'text-green-600' : 'text-amber-600'
          }`}>
            {selectedTools.length}/2 herramientas seleccionadas
            {selectedTools.length < 2 && ' ⚠️ Mínimo 2 para publicar'}
          </p>
        )}
      </div>

      {/* Navegación */}
      <div className="flex items-center justify-between pt-4 border-t">
        {onBack && (
          <button
            type="button"
            onClick={onBack}
            className="px-4 py-2 text-gray-700 hover:text-gray-900 font-medium"
          >
            ← Atrás
          </button>
        )}
        <div className={onBack ? '' : 'ml-auto'}>
          <button
            type="submit"
            className="px-6 py-2.5 bg-purple-600 text-white rounded-lg hover:bg-purple-700 font-medium transition-colors"
          >
            Siguiente →
          </button>
        </div>
      </div>
    </form>
  );
}
ENDOFFILE

# --- Paso 5: AgentPackPreview.jsx ---
cat > src/components/builder/AgentPackPreview.jsx << 'ENDOFFILE'
/**
 * Paso 5: Generación y descarga de agent-pack.yaml
 */
import { useState, useEffect } from 'react';
import { saveAs } from 'file-saver';
import jsyaml from 'js-yaml';
import { FileCode, Download, Copy, Check, AlertCircle } from 'lucide-react';

export default function AgentPackPreview({ botConfig, userCredential, onConfirm, onBack }) {
  const [yamlContent, setYamlContent] = useState('');
  const [envContent, setEnvContent] = useState('');
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState(null);

  const generateAgentPack = () => {
    try {
      const agentPack = {
        version: '1.0',
        meta {
          name: botConfig.name,
          profession: botConfig.profession || '',
          description: botConfig.description || '',
          category: botConfig.category || 'other',
          avatar: botConfig.avatar || '🤖'
        },
        identity: {
          credential_definition_id: userCredential?.cred_def_id || import.meta.env.PUBLIC_CRED_DEF_ID,
          org_url: 'organization.eafit.testnet.verana.network'
        },
        llm: {
          provider: botConfig.model?.provider || 'openai',
          model: botConfig.model?.name || 'gpt-4o-mini',
          parameters: {
            temperature: botConfig.params?.temperature || 0.7,
            max_tokens: botConfig.params?.max_tokens || 2048,
            language: botConfig.params?.language || 'es'
          }
        },
        prompt: {
          system: botConfig.system_prompt,
          welcome_message: botConfig.welcome_message || '¡Hola! ¿En qué puedo ayudarte?',
          tone: botConfig.tone || 'professional',
          capabilities: botConfig.capabilities || []
        },
        mcp_tools: (botConfig.mcp_service_ids || []).map(id => ({
          id,
          enabled: true
        })),
        hologram: {
          slug: botConfig.service_slug,
          public_url: botConfig.agent_public_url,
          qr_enabled: true
        }
      };

      return jsyaml.dump(agentPack, { 
        lineWidth: -1,
        noRefs: true,
        quotingType: '"'
      });
    } catch (err) {
      setError(`Error generando YAML: ${err.message}`);
      return null;
    }
  };

  const generateConfigEnv = () => {
    const slug = botConfig.service_slug || botConfig.name.toLowerCase().replace(/\s+/g, '-');
    
    return `# Generated by PersonaOS - ${new Date().toISOString()}
# ========================================
# CONFIGURACIÓN PARA eafit-challenge-agent-example
# ========================================

# Identidad del Agente
AGENT_NAME=${slug}
AGENT_DISPLAY_NAME=${botConfig.name}
AGENT_PROFESSION=${botConfig.profession || 'Asistente'}

# LLM Configuration
LLM_PROVIDER=${botConfig.model?.provider || 'openai'}
LLM_MODEL=${botConfig.model?.name || 'gpt-4o-mini'}
LLM_TEMPERATURE=${botConfig.params?.temperature || 0.7}
LLM_MAX_TOKENS=${botConfig.params?.max_tokens || 2048}
LLM_LANGUAGE=${botConfig.params?.language || 'es'}

# API Keys (CONFIGURAR EN RENDER/K8s - NUNCA subir a git)
# OPENAI_API_KEY=sk-xxx
# ANTHROPIC_API_KEY=sk-ant-xxx

# MCP Services (IDs del backend EAFIT)
MCP_SERVICE_IDS=${botConfig.mcp_service_ids?.join(',') || ''}

# Hologram / Verana Network
HOLOGRAM_SLUG=${botConfig.service_slug || ''}
CREDENTIAL_DEFINITION_ID=${import.meta.env.PUBLIC_CRED_DEF_ID}
ORG_VS_PUBLIC_URL=organization.eafit.testnet.verana.network

# Deployment
AGENT_PUBLIC_URL=${botConfig.agent_public_url || 'http://localhost:3011'}
REDIS_URL=redis://localhost:6379
DATABASE_URL=postgresql://user:pass@localhost:5432/eafit_challenge

# Ports (no modificar)
VS_AGENT_PORT=3010
CHATBOT_PORT=3003
`;
  };

  useEffect(() => {
    const yaml = generateAgentPack();
    const env = generateConfigEnv();
    
    if (yaml) {
      setYamlContent(yaml);
      setEnvContent(env);
    }
  }, [botConfig]);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(yamlContent);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      alert('Error al copiar: ' + err.message);
    }
  };

  const handleDownloadYaml = () => {
    const blob = new Blob([yamlContent], { type: 'application/x-yaml' });
    const filename = `agent-pack-${botConfig.service_slug || 'agent'}.yaml`;
    saveAs(blob, filename);
  };

  const handleDownloadEnv = () => {
    const blob = new Blob([envContent], { type: 'text/plain' });
    saveAs(blob, 'config.env');
  };

  const handleSubmit = () => {
    onConfirm({
      ...botConfig,
      agent_pack_yaml: yamlContent,
      config_env: envContent
    });
  };

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mb-4" />
        <p className="text-red-600 font-medium mb-2">{error}</p>
        <button 
          onClick={() => window.location.reload()}
          className="text-purple-600 hover:text-purple-700 font-medium"
        >
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Preview del YAML */}
      <div>
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-3">
          <FileCode className="w-4 h-4" />
          agent-pack.yaml — Preview
        </label>
        
        <div className="relative">
          <pre className="p-4 bg-gray-900 text-gray-100 rounded-lg text-xs overflow-x-auto max-h-80 font-mono">
            <code>{yamlContent || 'Generando...'}</code>
          </pre>
          
          <button
            onClick={handleCopy}
            className="absolute top-2 right-2 p-1.5 bg-gray-700 hover:bg-gray-600 rounded text-white transition-colors"
            title={copied ? '¡Copiado!' : 'Copiar YAML'}
          >
            {copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Acciones de descarga */}
      <div className="flex flex-wrap gap-3">
        <button
          onClick={handleDownloadYaml}
          className="inline-flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 font-medium transition-colors"
        >
          <Download className="w-4 h-4" />
          Descargar agent-pack.yaml
        </button>
        
        <button
          onClick={handleDownloadEnv}
          className="inline-flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-900 rounded-lg hover:bg-gray-200 font-medium transition-colors"
        >
          <Download className="w-4 h-4" />
          Descargar config.env
        </button>
      </div>

      {/* Notas importantes */}
      <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg">
        <h4 className="font-medium text-amber-900 mb-2">⚠️ Importante para el despliegue</h4>
        <ul className="text-sm text-amber-800 space-y-1 list-disc list-inside">
          <li>Los archivos se descargarán a tu carpeta <code>Downloads</code></li>
          <li>Cópialos a tu repositorio <code>eafit-challenge-agent-example/</code></li>
          <li><strong>Nunca</strong> commits <code>config.env</code> con API Keys reales</li>
          <li>Configura las API Keys como variables de entorno en Render/Kubernetes</li>
        </ul>
      </div>

      {/* Navegación */}
      <div className="flex items-center justify-between pt-4 border-t">
        {onBack && (
          <button
            type="button"
            onClick={onBack}
            className="px-4 py-2 text-gray-700 hover:text-gray-900 font-medium"
          >
            ← Atrás
          </button>
        )}
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={handleSubmit}
            className="px-6 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium transition-colors"
          >
            ✓ Guardar Agente
          </button>
        </div>
      </div>
    </div>
  );
}
ENDOFFILE

log_success "Componentes del wizard generados (5 pasos)"

# =============================================================================
# 13. COMPONENTE: HologramConnect.jsx
# =============================================================================
log_step "Generando componente de conexión con Hologram"

mkdir -p src/components/hologram

cat > src/components/hologram/HologramConnect.jsx << 'ENDOFFILE'
/**
 * Componente de conexión con Hologram Network
 * Muestra estado de publicación, QR y comandos de despliegue
 */
import { useState, useEffect } from 'react';
import { QrCode, RefreshCw, ExternalLink, Terminal, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import apiClient from '../../lib/api-client';

export default function HologramConnect({ botId, botSlug, onPublishSuccess }) {
  const { token } = useAuth();
  
  const [bot, setBot] = useState(null);
  const [loading, setLoading] = useState(true);
  const [publishing, setPublishing] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const fetchBot = async () => {
    if (!botId || !token) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const {  data } = await apiClient.bots.get(botId, token);
      setBot(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handlePublish = async () => {
    if (!botId || !token) return;
    
    // Validaciones previas
    if (!bot?.service_slug) {
      alert('⚠️ El bot debe tener un service_slug configurado para publicar.');
      return;
    }
    
    if (!bot?.agent_public_url) {
      alert('⚠️ Debes configurar la URL pública de tu VS Agent (ngrok/k8s) antes de publicar.');
      return;
    }

    setPublishing(true);
    setError(null);
    
    try {
      const {  publishedBot } = await apiClient.bots.publish(
        botId,
        bot.service_slug,
        bot.agent_public_url,
        token
      );
      
      setBot(publishedBot);
      setSuccess('✓ Agente publicado exitosamente en Hologram');
      onPublishSuccess?.(publishedBot);
      
    } catch (err) {
      setError(err.message || 'Error al publicar el agente');
    } finally {
      setPublishing(false);
    }
  };

  const handleUnpublish = async () => {
    if (!confirm('¿Despublicar este agente? Dejará de estar disponible en Hologram.')) {
      return;
    }
    
    try {
      const {  updatedBot } = await apiClient.bots.unpublish(botId, token);
      setBot(updatedBot);
      setSuccess('✓ Agente despublicado');
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    fetchBot();
  }, [botId, token]);

  // Estado: Cargando
  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <Loader2 className="w-6 h-6 animate-spin text-purple-500 mr-2" />
        <span className="text-gray-600">Consultando estado en Hologram...</span>
      </div>
    );
  }

  // Estado: Error
  if (error && !bot) {
    return (
      <div className="flex items-center gap-2 text-red-600 py-4">
        <AlertCircle className="w-5 h-5" />
        <span>{error}</span>
        <button onClick={fetchBot} className="text-purple-600 ml-2">Reintentar</button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Mensajes de estado */}
      {success && (
        <div className="flex items-center gap-2 p-3 bg-green-50 border border-green-200 rounded-lg text-green-800">
          <CheckCircle className="w-5 h-5" />
          <span>{success}</span>
        </div>
      )}
      
      {error && bot && (
        <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-800">
          <AlertCircle className="w-5 h-5" />
          <span>{error}</span>
        </div>
      )}

      {/* Selector de agente */}
      {bot && (
        <div className="flex items-center gap-3 p-4 bg-gray-50 rounded-lg">
          <span className="text-2xl">{bot.avatar || '🤖'}</span>
          <div className="flex-1">
            <h4 className="font-medium text-gray-900">{bot.name}</h4>
            <p className="text-sm text-gray-600">
              <code className="bg-gray-200 px-1 rounded">{bot.service_slug}</code>
            </p>
          </div>
          <button
            onClick={fetchBot}
            disabled={loading}
            className="p-2 text-gray-500 hover:text-purple-600 transition-colors"
            title="Actualizar estado"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      )}

      {/* Estado de publicación */}
      <div className="p-4 border rounded-lg">
        <h4 className="font-medium text-gray-900 mb-3">Estado en Hologram</h4>
        
        {bot?.is_published ? (
          // === PUBLICADO ===
          <div className="space-y-4">
            <div className="flex items-center gap-2 text-green-700 font-medium">
              <CheckCircle className="w-5 h-5" />
              <span>✓ Publicado</span>
            </div>
            
            {/* QR Code */}
            {bot.qr_code && (
              <div className="flex flex-col items-center p-4 bg-gray-50 rounded-lg">
                <img 
                  src={bot.qr_code} 
                  alt="QR Hologram" 
                  className="w-40 h-40 object-contain mb-3"
                />
                <p className="text-sm text-gray-600 text-center mb-3">
                  Escanea con <a href="https://hologram.zone" target="_blank" className="text-purple-600 hover:underline">Hologram Messaging</a>
                </p>
                <a
                  href={bot.hologram_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                >
                  <ExternalLink className="w-4 h-4" />
                  Abrir en Hologram
                </a>
              </div>
            )}
            
            {/* URL del agente */}
            {bot.hologram_url && (
              <div className="p-3 bg-gray-50 rounded text-sm">
                <span className="text-gray-600">URL: </span>
                <a href={bot.hologram_url} target="_blank" className="text-purple-600 break-all">
                  {bot.hologram_url}
                </a>
              </div>
            )}
            
            <button
              onClick={handleUnpublish}
              disabled={publishing}
              className="px-4 py-2 text-red-600 border border-red-300 rounded-lg hover:bg-red-50 transition-colors disabled:opacity-50"
            >
              ↓ Despublicar
            </button>
          </div>
        ) : (
          // === NO PUBLICADO ===
          <div className="space-y-4">
            <div className="flex items-center gap-2 text-gray-600">
              <AlertCircle className="w-5 h-5" />
              <span>Estado: <strong>No publicado</strong></span>
            </div>
            
            {/* Requisitos previos */}
            <div className="space-y-2 text-sm">
              <p className="font-medium text-gray-700">Para publicar, necesitas:</p>
              <ol className="list-decimal list-inside space-y-1 text-gray-600">
                <li>✓ Configurar slug único del servicio</li>
                <li className={bot?.agent_public_url ? 'text-green-600' : ''}>
                  {bot?.agent_public_url ? '✓' : '○'} Configurar URL pública del VS Agent (ngrok/k8s)
                </li>
                <li>○ Obtener Avatar Credential en Hologram</li>
                <li>○ Iniciar stack Docker y exponer puerto</li>
              </ol>
            </div>
            
            {/* Botón de publicación */}
            <button
              onClick={handlePublish}
              disabled={publishing || !bot?.agent_public_url}
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-purple-600 text-white rounded-lg hover:bg-purple-700 font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {publishing ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Publicando...
                </>
              ) : (
                <>
                  <QrCode className="w-4 h-4" />
                  ↑ Publicar en Hologram
                </>
              )}
            </button>
          </div>
        )}
      </div>

      {/* Comandos Quick Start */}
      <details className="group">
        <summary className="flex items-center gap-2 text-sm font-medium text-gray-700 cursor-pointer list-none">
          <Terminal className="w-4 h-4" />
          Quick Start — Comandos para Debian 12 ARM64
          <span className="transition-transform group-open:rotate-180 ml-auto">▼</span>
        </summary>
        
        <div className="mt-4 p-4 bg-gray-900 rounded-lg overflow-x-auto">
          <pre className="text-xs text-gray-100 font-mono whitespace-pre">
{`# 1. Clonar el agente de ejemplo
$ git clone git@github.com:Danielsma803/eafit-challenge-agent-example.git
$ cd eafit-challenge-agent-example

# 2. Copiar archivos generados desde PersonaOS
$ cp ~/Downloads/agent-pack.yaml app/agent-packs/example-agent/
$ cp ~/Downloads/config.env .

# 3. Setup: obtener Service Credential
$ source config.env && ./scripts/setup.sh

# 4. Iniciar stack completo
$ export OPENAI_API_KEY=sk-ant-xxx  # Tu API key real
$ ./scripts/start.sh

# 5. Exponer con ngrok para Hologram
$ ngrok http 3011
# → Copia la URL https de ngrok y actualiza AGENT_PUBLIC_URL

# 6. Verificar que el agente está online
$ curl http://localhost:3010/agent-info
$ curl http://localhost:3003/health

# 7. ¡Listo! Vuelve a PersonaOS y publica tu agente 🚀`}
          </pre>
        </div>
        
        {/* Enlaces útiles */}
        <div className="mt-4 flex flex-wrap gap-2">
          <a 
            href="https://github.com/Danielsma803/eafit-challenge-agent-example"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-sm text-purple-600 hover:underline"
          >
            🐙 Fork GitHub
          </a>
          <a 
            href="https://avatar.eafit.testnet.verana.network/"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-sm text-purple-600 hover:underline"
          >
            🪪 Avatar Credential
          </a>
          <a 
            href="https://hologram.zone"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-sm text-purple-600 hover:underline"
          >
            📱 Hologram Messaging
          </a>
        </div>
      </details>
    </div>
  );
}
ENDOFFILE
log_success "HologramConnect.jsx generado"

# =============================================================================
# 14. PÁGINAS ASTRO PRINCIPALES
# =============================================================================
log_step "Generando páginas Astro principales"

# --- src/pages/index.astro (Redirect inicial) ---
cat > src/pages/index.astro << 'ENDOFFILE'
---
// src/pages/index.astro
// Redirect a dashboard si autenticado, o a landing si no

import { redirect } from 'astro:middleware';

export const prerender = false;

export async function GET({ cookies, redirect }) {
  const token = cookies.get('session_token')?.value;
  const landingUrl = import.meta.env.PUBLIC_LANDING_URL || 'https://landing-l4tx.onrender.com';
  
  if (!token) {
    // Sin sesión → redirigir a landing
    return redirect(landingUrl, 302);
  }
  
  // Con sesión → dashboard
  return redirect('/dashboard', 302);
}
---
ENDOFFILE

# --- src/pages/dashboard.astro ---
mkdir -p src/pages
cat > src/pages/dashboard.astro << 'ENDOFFILE'
---
// src/pages/dashboard.astro
// Panel principal de PersonaOS

import { requireAuth } from '../middleware/auth';
import BotsList from '../components/dashboard/BotsList.jsx';

export const prerender = false;

// Verificar autenticación
const user = await requireAuth({ cookies, redirect, request }).catch(() => null);

if (!user) {
  // Redirección manejada por el middleware
  return new Response(null, { 
    status: 302, 
    headers: { Location: import.meta.env.PUBLIC_LANDING_URL } 
  });
}
---

<!doctype html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>◈ PersonaOS — Mis Agentes</title>
  <meta name="description" content="Crea y gestiona tus Agentes IA verificables en Hologram Network" />
  
  <!-- Favicon -->
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  
  <!-- Tailwind CSS (CDN para desarrollo) -->
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      theme: {
        extend: {
          colors: {
            purple: {
              50: '#f5f3ff',
              100: '#ede9fe',
              500: '#8b5cf6',
              600: '#7c3aed',
              700: '#6d28d9',
            }
          }
        }
      }
    }
  </script>
</head>
<body class="min-h-screen bg-gray-50">
  <!-- Header -->
  <header class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        <!-- Logo -->
        <div class="flex items-center gap-3">
          <span class="text-2xl">◈</span>
          <h1 class="text-xl font-bold text-gray-900">PersonaOS</h1>
        </div>
        
        <!-- Navigation -->
        <nav class="flex items-center gap-4">
          <a href="/dashboard" class="text-gray-900 font-medium">Mis Bots</a>
          <a href="/bot/new" class="text-gray-600 hover:text-gray-900">+ Crear</a>
          <a href="/settings" class="text-gray-600 hover:text-gray-900">⚙ Config</a>
          
          <!-- User menu -->
          <div class="flex items-center gap-3 ml-4 pl-4 border-l">
            <span class="text-sm text-gray-600 hidden sm:inline">
              {user.name}
            </span>
            <button
              onclick="fetch('/auth/logout', {method:'POST'}).then(()=>window.location.href=import.meta.env.PUBLIC_LANDING_URL)"
              class="text-sm text-red-600 hover:text-red-700 font-medium"
            >
              Cerrar sesión
            </button>
          </div>
        </nav>
      </div>
    </div>
  </header>

  <!-- Main Content -->
  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Welcome -->
    <div class="mb-8">
      <h2 class="text-2xl font-bold text-gray-900">
        👋 Hola, {user.name}
      </h2>
      <p class="text-gray-600 mt-1">
        Gestiona tus Persona AI Agents desplegados en Hologram Network
      </p>
    </div>

    {/* Lista de Bots (React component) */}
    <BotsList client:load user={user} />
  </main>

  <!-- Footer -->
  <footer class="border-t border-gray-200 mt-12 py-6">
    <div class="max-w-7xl mx-auto px-4 text-center text-sm text-gray-500">
      <p>
        ◈ PersonaOS • Reto EAFIT Challenge • 
        <a href="https://discord.com/invite/edjaFn252q" target="_blank" class="text-purple-600 hover:underline">
          #eafit-challenge en Discord
        </a>
      </p>
    </div>
  </footer>
</body>
</html>
ENDOFFILE

log_success "Páginas Astro generadas: index.astro, dashboard.astro"

# =============================================================================
# 15. CONFIGURACIÓN DE DESPLIEGUE
# =============================================================================
log_step "Generando configuración de despliegue (Vercel + Render)"

# --- vercel.json ---
cat > vercel.json << EOF
{
  "version": 2,
  "buildCommand": "${PKG_MGR} run build",
  "outputDirectory": "dist",
  "devCommand": "${PKG_MGR} run dev",
  "installCommand": "${PKG_INSTALL}",
  "framework": "astro",
  "regions": ["sao1"],
  "env": {
    "PUBLIC_API_URL": "${API_URL}",
    "PUBLIC_LANDING_URL": "${LANDING_URL}",
    "PUBLIC_HOLOGRAM_URL": "${HOLOGRAM_URL}",
    "PUBLIC_VERANA_NETWORK": "${VERANA_NETWORK}",
    "PUBLIC_CRED_DEF_ID": "${CRED_DEF_ID}"
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-XSS-Protection", "value": "1; mode=block" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    }
  ]
}
EOF

# --- render.yaml ---
cat > render.yaml << EOF
services:
  - type: web
    name: ${PROJECT_NAME}
    env: static
    buildCommand: ${PKG_INSTALL} && ${PKG_RUN} build
    staticPublishPath: ./dist
    headers:
      - path: /*
        name: X-Content-Type-Options
        value: nosniff
      - path: /*
        name: X-Frame-Options
        value: DENY
    envVars:
      - key: PUBLIC_API_URL
        value: ${API_URL}
      - key: PUBLIC_LANDING_URL
        value: ${LANDING_URL}
      - key: PUBLIC_HOLOGRAM_URL
        value: ${HOLOGRAM_URL}
      - key: PUBLIC_VERANA_NETWORK
        value: ${VERANA_NETWORK}
      - key: PUBLIC_CRED_DEF_ID
        value: ${CRED_DEF_ID}
EOF

log_success "Configuración de despliegue: vercel.json + render.yaml"

# =============================================================================
# 16. INSTALACIÓN DE DEPENDENCIAS
# =============================================================================
log_step "Instalando dependencias con $PKG_MGR..."

$PKG_INSTALL

log_success "Dependencias instaladas ✓"

# =============================================================================
# 17. VALIDACIÓN FINAL
# =============================================================================
log_step "Validando estructura del proyecto..."

REQUIRED_FILES=(
  "package.json"
  "astro.config.mjs"
  ".env.example"
  "src/lib/api-client.js"
  "src/hooks/useAuth.js"
  "src/middleware/auth.js"
  "src/pages/auth/callback.astro"
  "src/pages/dashboard.astro"
  "src/components/auth/GoogleLoginButton.jsx"
  "src/components/dashboard/BotsList.jsx"
  "src/components/builder/BotForm.jsx"
  "src/components/builder/ModelSelector.jsx"
  "src/components/builder/PromptEditor.jsx"
  "src/components/builder/MCPToolsConfig.jsx"
  "src/components/builder/AgentPackPreview.jsx"
  "src/components/hologram/HologramConnect.jsx"
)

ALL_OK=true
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    log_error "Falta archivo crítico: $file"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" = false ]; then
  log_error "✗ Algunos archivos faltan. Revisa los errores arriba."
  exit 1
fi

log_success "✓ Todos los archivos críticos generados y validados"

# =============================================================================
# 18. MENSAJE FINAL Y PRÓXIMOS PASOS
# =============================================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉 ¡Integración PersonaOS + Backend EAFIT LISTA!    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Próximos pasos para ejecutar:${NC}"
echo "  1. Revisar .env.local y ajustar si es necesario"
echo "  2. Iniciar servidor de desarrollo:"
echo "     ${CYAN}$ ${PKG_RUN} dev${NC}"
echo "  3. Abrir navegador: ${CYAN}http://localhost:4321${NC}"
echo "  4. Probar flujo completo:"
echo "     • Landing → Google OAuth → PersonaOS"
echo "     • Crear bot mínimo → Descargar agent-pack.yaml"
echo "     • Publicar → Obtener QR → Escanear en hologram.zone"
echo ""

if [ -n "$PROD_DOMAIN" ]; then
  echo -e "${YELLOW}🌐 Para despliegue en producción:${NC}"
  echo "  • Desplegar con: ${CYAN}${PKG_MGR} exec vercel --prod${NC}"
  echo "  • O alternativamente: ${CYAN}git push render main${NC}"
  echo "  • Actualizar CORS en backend con: ${CYAN}https://${PROD_DOMAIN}${NC}"
  echo "  • Configurar variables de entorno en Vercel/Render Dashboard"
  echo ""
fi

echo -e "${BLUE}🔗 Recursos útiles:${NC}"
echo "  • API Docs Backend: ${API_URL%/}/../api-docs"
echo "  • Landing OAuth: ${LANDING_URL}"
echo "  • Hologram Network: ${HOLOGRAM_URL}"
echo "  • Verana Network: ${VERANA_NETWORK}"
echo "  • Discord del reto: https://discord.com/invite/edjaFn252q #eafit-challenge"
echo "  • Schema Agent Pack: https://github.com/2060-io/hologram-generic-ai-agent-vs/blob/main/docs/agent-pack-schema.md"
echo ""

echo -e "${CYAN}🚀 ¿Listo para entregar tu solución al reto EAFIT?${NC}"
echo "   1. Crea el repo en GitHub: ${PROJECT_NAME}"
echo "   2. Commit inicial: git add . && git commit -m 'feat: integración PersonaOS + EAFIT backend'"
echo "   3. Despliega en Vercel/Render"
echo "   4. Actualiza CORS en backend con la URL de producción"
echo "   5. ¡Entrega y demuestra el flujo completo! 🎓✨"
echo ""

# =============================================================================
# 19. SCRIPT DE VALIDACIÓN ADICIONAL (opcional)
# =============================================================================
# Crear script de validación para CI/CD
mkdir -p scripts

cat > scripts/validate-integration.sh << 'VALIDATEEOF'
#!/bin/bash
# validate-integration.sh — Verifica integración PersonaOS ↔ Backend EAFIT

API_URL="${PUBLIC_API_URL:-https://eafit-challenge-back.onrender.com/api/v1}"
TOKEN="${TEST_TOKEN:-}"

echo "🔍 Validando integración PersonaOS ↔ Backend EAFIT"
echo "=================================================="

# 1. Health check del backend
echo -n "✓ Backend health... "
if curl -sf "${API_URL%/}/health" > /dev/null 2>&1; then
  echo "OK"
else
  echo "FAIL ❌"
  exit 1
fi

# 2. Listar proveedores LLM (público)
echo -n "✓ GET /llm-providers... "
if curl -sf "${API_URL}/llm-providers" | jq -e '.[0].name' > /dev/null 2>&1; then
  echo "OK"
else
  echo "FAIL ❌"
  exit 1
fi

# 3. Auth me (requiere token)
if [ -n "$TOKEN" ]; then
  echo -n "✓ GET /auth/me... "
  if curl -sf -H "Authorization: Bearer $TOKEN" "${API_URL}/auth/me" | jq -e '.email' > /dev/null 2>&1; then
    echo "OK"
  else
    echo "FAIL ❌ (token inválido)"
  fi
  
  echo -n "✓ GET /bots... "
  if curl -sf -H "Authorization: Bearer $TOKEN" "${API_URL}/bots" | jq -e 'type == "array"' > /dev/null 2>&1; then
    echo "OK"
  else
    echo "FAIL ❌"
  fi
else
  echo "⚠️  Sin TEST_TOKEN: saltando pruebas autenticadas"
  echo "   Para probar: export TEST_TOKEN=eyJ..."
fi

echo ""
echo "✅ Validación completada"
VALIDATEEOF

chmod +x scripts/validate-integration.sh
log_success "Script de validación creado: scripts/validate-integration.sh"

exit 0
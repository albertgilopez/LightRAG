#!/bin/bash

echo "========================================="
echo "🚀 Script para Push y PR de LightRAG Fix"
echo "========================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d ".git" ]; then
    echo "❌ Error: No estás en un repositorio git"
    echo "   Por favor, ejecuta desde /home/Usuario/lightrag-fork"
    exit 1
fi

# Mostrar estado actual
echo "📋 Estado actual del repositorio:"
git status --short
echo ""

# Mostrar el último commit
echo "📝 Último commit:"
git log -1 --oneline
echo ""

# Verificar remotes
echo "🔗 Remotes configurados:"
git remote -v
echo ""

# Instrucciones para push
echo "========================================="
echo "📤 INSTRUCCIONES PARA PUSH"
echo "========================================="
echo ""
echo "1. Si aún NO has hecho fork en GitHub:"
echo "   👉 Ve a https://github.com/HKUDS/LightRAG"
echo "   👉 Click en 'Fork' (arriba a la derecha)"
echo "   👉 Espera que se complete el fork"
echo ""
echo "2. Ejecuta estos comandos para hacer push:"
echo ""
echo "   # Si usas HTTPS (usuario y contraseña):"
echo "   git push -u origin fix-storage-lock-async-error"
echo ""
echo "   # Si usas SSH (con clave SSH configurada):"
echo "   git remote set-url origin git@github.com:albertgilopez/LightRAG.git"
echo "   git push -u origin fix-storage-lock-async-error"
echo ""
echo "   # Si tienes 2FA activado, necesitarás un Personal Access Token"
echo "   # Créalo en: https://github.com/settings/tokens"
echo ""
echo "3. Después del push exitoso, ve a:"
echo "   👉 https://github.com/albertgilopez/LightRAG"
echo "   👉 Verás un banner amarillo: 'fix-storage-lock-async-error had recent pushes'"
echo "   👉 Click en 'Compare & pull request'"
echo ""
echo "========================================="
echo "📝 CREAR EL PULL REQUEST"
echo "========================================="
echo ""
echo "4. En la página del PR:"
echo "   • Título: fix: Initialize storage_lock to resolve AttributeError: __aenter__ (Fixes #1933)"
echo "   • Descripción: Usa el contenido de PR_TEMPLATE.md"
echo "   • Asegúrate que dice 'Fixes #1933'"
echo "   • Click en 'Create pull request'"
echo ""
echo "5. Después de crear el PR:"
echo "   • Comenta en el issue #1933 con el link al PR"
echo "   • Monitorea por feedback de los maintainers"
echo ""
echo "========================================="
echo "✅ ¡Buena suerte con tu contribución!"
echo "========================================="
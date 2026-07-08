# Propuestas de Mejoras para LightRAG

## 1. Mejoras en Mensajes de Error

### Problema Actual
Cuando los usuarios no inicializan correctamente LightRAG, reciben errores crípticos como:
- `AttributeError: __aenter__` 
- `KeyError: 'history_messages'`

Estos mensajes no son intuitivos y no indican claramente qué debe hacer el usuario.

### Propuesta: Agregar Verificaciones y Mensajes Claros

#### A. En `lightrag/kg/json_doc_status_impl.py` y similares

```python
async def filter_keys(self, keys: list[str]) -> set[str]:
    if self._storage_lock is None:
        raise RuntimeError(
            "Storage not initialized. Please call 'await rag.initialize_storages()' "
            "after creating your LightRAG instance.\n"
            "Example:\n"
            "  rag = LightRAG(...)\n"
            "  await rag.initialize_storages()\n"
            "  await initialize_pipeline_status()"
        )
    async with self._storage_lock:
        return set(keys) - set(self._data.keys())
```

#### B. En `lightrag/lightrag.py` - Agregar método de verificación

```python
def _check_initialization(self, operation_name: str = "operation"):
    """Check if storages are initialized before operations"""
    if self._storages_status != StoragesStatus.INITIALIZED:
        raise RuntimeError(
            f"Cannot perform {operation_name}: LightRAG not fully initialized.\n"
            f"Current status: {self._storages_status.name}\n\n"
            "Please initialize LightRAG properly:\n"
            "  rag = LightRAG(...)\n"
            "  await rag.initialize_storages()\n"
            "  await initialize_pipeline_status()\n\n"
            "See: https://github.com/HKUDS/LightRAG#important-initialization-requirements"
        )
```

#### C. En `lightrag/kg/shared_storage.py` - Mejorar el error de history_messages

```python
def get_namespace_data(namespace: str):
    """Get namespace data with better error handling"""
    if namespace not in _namespace_data:
        raise KeyError(
            f"Namespace '{namespace}' not found. This usually means pipeline status was not initialized.\n"
            "Please call 'await initialize_pipeline_status()' after initializing storages.\n"
            "Full initialization sequence:\n"
            "  rag = LightRAG(...)\n"
            "  await rag.initialize_storages()\n"
            "  await initialize_pipeline_status()"
        )
    return _namespace_data[namespace]
```

## 2. Mejoras en la Documentación

### A. Agregar una sección de "Quick Troubleshooting" al principio del README

```markdown
## ⚡ Quick Troubleshooting Guide

If you see these errors, here's the fix:

| Error | Solution |
|-------|----------|
| `AttributeError: __aenter__` | Add `await rag.initialize_storages()` after creating LightRAG |
| `KeyError: 'history_messages'` | Add `await initialize_pipeline_status()` after storage init |
| Both errors | You forgot both initialization steps - see example below |

**Correct initialization:**
```python
rag = LightRAG(...)
await rag.initialize_storages()  # ← Don't forget this!
await initialize_pipeline_status()  # ← And this!
```
```

### B. Mejorar los ejemplos con comentarios más claros

```python
# examples/lightrag_openai_demo.py
import asyncio
from lightrag import LightRAG
from lightrag.kg.shared_storage import initialize_pipeline_status

async def main():
    # Step 1: Create LightRAG instance
    rag = LightRAG(
        working_dir="./rag_storage",
        embedding_func=openai_embed,
        llm_model_func=gpt_4o_mini_complete,
    )
    
    # Step 2: CRITICAL - Initialize storages (prevents AttributeError)
    await rag.initialize_storages()
    
    # Step 3: CRITICAL - Initialize pipeline (prevents KeyError)
    await initialize_pipeline_status()
    
    # Now you can use LightRAG safely
    await rag.insert("Your text here")
```

### C. Agregar un script de diagnóstico

Crear `lightrag/tools/check_initialization.py`:

```python
"""
Diagnostic tool to check LightRAG initialization status
"""
import asyncio
from lightrag import LightRAG
from lightrag.kg.shared_storage import initialize_pipeline_status

async def check_lightrag_setup(rag_instance):
    """Check if a LightRAG instance is properly initialized"""
    issues = []
    
    # Check storage initialization
    if not hasattr(rag_instance, '_storages_status'):
        issues.append("LightRAG instance missing _storages_status attribute")
    elif rag_instance._storages_status != StoragesStatus.INITIALIZED:
        issues.append(f"Storages not initialized (status: {rag_instance._storages_status})")
    
    # Check individual storage components
    storage_components = [
        'full_docs', 'text_chunks', 'entities_vdb', 
        'relationships_vdb', 'chunks_vdb', 'doc_status'
    ]
    
    for component in storage_components:
        if not hasattr(rag_instance, component):
            issues.append(f"Missing storage component: {component}")
        else:
            storage = getattr(rag_instance, component)
            if hasattr(storage, '_storage_lock') and storage._storage_lock is None:
                issues.append(f"Storage {component} not initialized (lock is None)")
    
    # Check pipeline status
    try:
        from lightrag.kg.shared_storage import get_namespace_data
        get_namespace_data("pipeline_status")
    except KeyError:
        issues.append("Pipeline status not initialized - call initialize_pipeline_status()")
    
    if issues:
        print("❌ Issues found:")
        for issue in issues:
            print(f"  - {issue}")
        print("\n📝 Fix by running:")
        print("  await rag.initialize_storages()")
        print("  await initialize_pipeline_status()")
        return False
    else:
        print("✅ LightRAG is properly initialized!")
        return True

# Usage example
if __name__ == "__main__":
    async def test():
        rag = LightRAG(working_dir="./test_storage")
        
        print("Before initialization:")
        await check_lightrag_setup(rag)
        
        print("\nAfter initialization:")
        await rag.initialize_storages()
        await initialize_pipeline_status()
        await check_lightrag_setup(rag)
    
    asyncio.run(test())
```

## 3. Agregar Inicialización Automática Opcional

### Propuesta: Parámetro auto_initialize

```python
# En lightrag/lightrag.py
@dataclass
class LightRAG:
    # ... otros campos ...
    
    auto_initialize: bool = field(default=False)
    """If True, automatically initialize storages on first use (may cause issues in some async contexts)"""
    
    async def _ensure_initialized(self):
        """Ensure storages are initialized before operations"""
        if self.auto_initialize and self._storages_status == StoragesStatus.CREATED:
            logger.warning(
                "Auto-initializing storages. For better control, explicitly call:\n"
                "  await rag.initialize_storages()\n"
                "  await initialize_pipeline_status()"
            )
            await self.initialize_storages()
            from lightrag.kg.shared_storage import initialize_pipeline_status
            await initialize_pipeline_status()
    
    async def insert(self, text: str, **kwargs):
        await self._ensure_initialized()  # Auto-init if enabled
        # ... resto del método
```

## 4. Mejorar la Documentación de Errores Comunes

Crear un archivo `docs/COMMON_ERRORS.md`:

```markdown
# Common Errors and Solutions

## Initialization Errors

### AttributeError: __aenter__

**Full error:**
```
AttributeError: __aenter__
File "lightrag/kg/json_doc_status_impl.py", line 60, in initialize
    async with self._storage_lock:
```

**Cause:** Storage backends are not initialized. The `_storage_lock` is `None`.

**Solution:**
```python
# After creating your LightRAG instance:
rag = LightRAG(...)
await rag.initialize_storages()  # ← Add this line
```

### KeyError: 'history_messages' or 'pipeline_status'

**Full error:**
```
KeyError: 'history_messages'
KeyError: 'pipeline_status'
```

**Cause:** Pipeline status tracking not initialized.

**Solution:**
```python
from lightrag.kg.shared_storage import initialize_pipeline_status

# After initializing storages:
await rag.initialize_storages()
await initialize_pipeline_status()  # ← Add this line
```

## Complete Working Example

```python
import asyncio
from lightrag import LightRAG, QueryParam
from lightrag.llm.openai import openai_embed, gpt_4o_mini_complete
from lightrag.kg.shared_storage import initialize_pipeline_status

async def main():
    # Create instance
    rag = LightRAG(
        working_dir="./rag_storage",
        embedding_func=openai_embed,
        llm_model_func=gpt_4o_mini_complete,
    )
    
    # CRITICAL: Initialize in correct order
    await rag.initialize_storages()        # Step 1
    await initialize_pipeline_status()      # Step 2
    
    # Now safe to use
    await rag.insert("Your text here")
    response = await rag.query("Your question")
    print(response)

if __name__ == "__main__":
    asyncio.run(main())
```
```

## 5. Pull Request Template

```markdown
## Improve error messages and documentation for initialization issues

### Description
This PR improves the developer experience by providing clear, actionable error messages when LightRAG is not properly initialized, and enhances documentation to prevent common initialization mistakes.

### Changes
1. **Better error messages**: Replace cryptic `AttributeError: __aenter__` with clear instructions
2. **Enhanced documentation**: Add troubleshooting guide and clarify initialization requirements
3. **Diagnostic tool**: New tool to check initialization status
4. **More examples**: Add comments explaining why initialization is needed

### Motivation
Based on user feedback (Issues #1933, #1934), many developers struggle with initialization errors. This PR makes the library more user-friendly by:
- Providing clear error messages that explain how to fix the problem
- Adding documentation that prevents the errors from occurring
- Creating tools to diagnose initialization issues

### Testing
- [ ] Tested error messages appear correctly when initialization is skipped
- [ ] Verified diagnostic tool correctly identifies initialization issues
- [ ] Confirmed examples work with proper initialization

### Related Issues
- Addresses feedback from #1933
- Improves upon closed PR #1934
```
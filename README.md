# Reposición Mateu para iOS

## Generar el proyecto

La fuente del proyecto se mantiene con XcodeGen para evitar que referencias
locales de Xcode queden fuera del repositorio.

1. Instalar XcodeGen en macOS.
2. Ejecutar `xcodegen generate` dentro de esta carpeta.
3. Abrir `RetailSystem.xcodeproj`.
4. Configurar el equipo de firma y el bundle identifier.

Debug usa la dirección local definida en `Config/Debug.xcconfig`. Release
requiere reemplazar `api.example.invalid` por una API HTTPS antes de distribuir.

## Seguridad y roles

Los tokens se guardan en Keychain. La navegación disponible depende del rol:

- `SYSTEM_OWNER` y `COMPANY_ADMIN`: panel completo y transferencias.
- `WAREHOUSE`: operación de transferencias.
- `BRANCH_MANAGER`: transferencias de su sucursal, rechazo previo al despacho
  y confirmación de recepción.

## Reposición por Excel

La pestaña Reposición permite trabajar mientras no exista integración directa
con TS:

- modo distribuido: cada encargado carga las ventas de su sucursal;
- modo centralizado: propietario o administrador carga las ventas de toda la
  empresa;
- propietario o administrador carga el stock, ejecuta el análisis y comparte
  el F8;
- las plantillas autorizadas se descargan desde la misma pantalla.

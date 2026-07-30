# Reposición Mateu para iOS

## Generar el proyecto

La fuente se mantiene con XcodeGen para evitar referencias locales de Xcode.

1. Instalá XcodeGen en macOS.
2. Ejecutá `xcodegen generate` dentro de esta carpeta.
3. Abrí `RetailSystem.xcodeproj`.
4. Configurá el equipo de firma y el bundle identifier.
5. Cambiá `API_BASE_URL` en `Config/Debug.xcconfig` por la IP de la Mac que
   ejecuta el backend. Para un iPhone físico no uses `localhost`.

La app requiere iOS 17 o posterior y se adapta a iPhone y iPad, tanto en
vertical como en horizontal. Release exige una URL HTTPS real.

## Flujo de reposición

- Por sucursal: cada encargado recibe una solicitud y carga su propio Excel de
  ventas; el administrador carga el stock general.
- Consolidado: el administrador carga un Excel con todas las ventas y otro con
  el stock general.
- En ambos modos el administrador genera el F8, lo revisa con la vista previa
  nativa de iOS y decide cuándo distribuirlo.
- Al distribuir se crean los movimientos. Cada encargado ve sólo lo que su
  sucursal prepara o recibe; depósito coordina la operación.
- Historial sólo consulta F8 ya generados. No acepta cargas.

Si se activa la validación estricta de período, el Excel de ventas debe incluir
`PERIODO_DESDE` y `PERIODO_HASTA`. Las plantillas descargables ya contienen
esas columnas.

## Roles

- `SYSTEM_OWNER`: acceso total y creación de administradores.
- `COMPANY_ADMIN`: operación global y gestión de usuarios operativos.
- `WAREHOUSE`: aprobación, preparación, despacho y recepción.
- `BRANCH_MANAGER`: ventas y movimientos de su sucursal.

Los tokens se almacenan en Keychain y las acciones sensibles se validan otra
vez en el backend.

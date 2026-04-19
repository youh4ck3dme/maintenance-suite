# Maintenance Suite Professional ⚡

Moderný, vysoko efektívny nástroj na údržbu a diagnostiku systému Windows, postavený na technológiách Electron a Fastify.

## Hlavné funkcie
- **Hĺbková diagnostika**: Analýza zdravia diskov (S.M.A.R.T.), využitia kapacity a identifikácia najväčších žrútov miesta.
- **Inteligentné čistenie**: Bezpečné odstraňovanie Windows Update cache, AppX balíkov a vývojárskeho balastu (NPM, PNPM, Docker).
- **Emergency Clean**: Špeciálny režim na uvoľnenie miesta v kritických situáciách (keď zostáva < 1GB).
- **Moderné UI**: Responzívny Dashboard s tmavým režimom a prémiovými ikonami.

## Ako začať
1. **Inštalácia závislostí**:
   ```bash
   cd Dashboard/electron
   npm install
   ```
2. **Spustenie aplikácie**:
   ```bash
   npm run electron:start
   ```

## Technológie
- **Frontend**: Vanilla JS, HTML5, CSS3 (Modern SaaS design).
- **Backend**: Fastify (Node.js).
- **Desktop**: Electron + Capacitor.
- **Engine**: Custom PowerShell automatizačné skripty.

---
*Created with ⚡ by Antigravity*

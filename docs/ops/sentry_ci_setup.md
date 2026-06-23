# Sentry CI Setup (Production Only)

## 1. Create Sentry Auth Token
- Go to [Sentry Auth Tokens Settings](https://sentry.io/settings/account/api/auth-tokens/)
- Create a token with the following scopes:
  - `project:write`
  - `project:read`
- Copy the generated token.

## 2. Add GitHub Secret
- Go to your GitHub repository -> Settings -> Secrets and variables -> Actions
- Click **New repository secret**
- Name: `SENTRY_AUTH_TOKEN`
- Value: Paste the Sentry Auth Token copied in step 1.

## 3. Update CI Workflow
In `.github/workflows/ci.yml`, add the `SENTRY_AUTH_TOKEN` environment variable to the `Build release APK` step:

```yaml
      - name: Build release APK (R8 shrink + Dart obfuscation)
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
        run: flutter build apk --release --obfuscate --split-debug-info=build/debug-symbols
```

## 4. Verify
- The CI build log should show that Sentry ProGuard mapping upload succeeded.
- The Sentry dashboard should show the mapping file under **Project Settings** -> **Debug Files**.

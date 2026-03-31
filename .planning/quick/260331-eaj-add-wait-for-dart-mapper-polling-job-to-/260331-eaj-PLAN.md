---
phase: quick
plan: 260331-eaj
type: execute
wave: 1
depends_on: []
files_modified:
  - .github/workflows/publish.yml
autonomous: true
requirements: []

must_haves:
  truths:
    - "dart_mapper_generator publish job waits until dart_mapper is indexed on pub.dev before running"
    - "The polling job exits 0 when pub.dev returns HTTP 200 for the published version"
    - "The polling job exits 1 with an error annotation after 20 failed attempts (~10 minutes)"
    - "The version polled is read dynamically from packages/dart_mapper/pubspec.yaml, not hardcoded"
  artifacts:
    - path: ".github/workflows/publish.yml"
      provides: "Updated publish workflow with wait_for_dart_mapper intermediate job"
      contains: "wait_for_dart_mapper"
  key_links:
    - from: "dart_runner job"
      to: "wait_for_dart_mapper job"
      via: "needs: dart_runner"
    - from: "wait_for_dart_mapper job"
      to: "dart_mapper_generator job"
      via: "needs: wait_for_dart_mapper"
---

<objective>
Add an intermediate `wait_for_dart_mapper` job to the publish workflow that polls pub.dev until the newly published `dart_mapper` package is indexed before the `dart_mapper_generator` publish job runs.

Purpose: The `dart_mapper_generator` package depends on `dart_mapper: ^1.0.0`. After `dart_mapper` is published, pub.dev takes ~5 minutes to index it. Without a wait step, `dart pub get` in the generator publish job fails because the version is not yet resolvable.

Output: Updated `.github/workflows/publish.yml` with a polling job between the two existing publish jobs.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@.planning/STATE.md
@.github/workflows/publish.yml
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add wait_for_dart_mapper polling job to publish.yml</name>
  <files>.github/workflows/publish.yml</files>
  <action>
Insert a new job `wait_for_dart_mapper` between the existing `dart_runner` and `dart_mapper_generator` jobs. Also update `dart_mapper_generator` to depend on `wait_for_dart_mapper` instead of `dart_runner`.

The complete updated `publish.yml` should be:

```yaml
name: Publish

on:
  workflow_call:


jobs:
  dart_runner:
    if: startsWith(github.ref, 'refs/tags/')
    permissions:
      id-token: write
    uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
    with:
      working-directory: packages/dart_mapper

  wait_for_dart_mapper:
    if: startsWith(github.ref, 'refs/tags/')
    needs: dart_runner
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Wait for dart_mapper to be indexed on pub.dev
        run: |
          VERSION=$(grep '^version:' packages/dart_mapper/pubspec.yaml | awk '{print $2}')
          echo "Waiting for dart_mapper $VERSION to be available on pub.dev..."
          MAX_ATTEMPTS=20
          ATTEMPT=0
          until [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/dart_mapper/versions/$VERSION")
            if [ "$STATUS" = "200" ]; then
              echo "dart_mapper $VERSION is available on pub.dev."
              exit 0
            fi
            ATTEMPT=$((ATTEMPT + 1))
            echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: pub.dev returned $STATUS. Retrying in 30 seconds..."
            sleep 30
          done
          echo "::error::dart_mapper $VERSION was not available on pub.dev after $((MAX_ATTEMPTS * 30)) seconds."
          exit 1

  dart_mapper_generator:
    if: startsWith(github.ref, 'refs/tags/')
    needs:
      - wait_for_dart_mapper
    permissions:
      id-token: write
    uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
    with:
      working-directory: packages/dart_mapper_generator
```

Key points:
- `wait_for_dart_mapper` needs `dart_runner` (not `dart_mapper` — the existing job is named `dart_runner`)
- `dart_mapper_generator` needs `wait_for_dart_mapper` (replacing its previous dependency on `dart_runner`)
- Version is extracted via `grep '^version:'` + `awk '{print $2}'` from the checked-out pubspec.yaml
- Polling: curl with `-s -o /dev/null -w "%{http_code}"` captures HTTP status code only
- 20 attempts × 30 seconds = up to 10 minutes maximum wait
- `::error::` annotation surfaces the failure in the GitHub Actions UI
  </action>
  <verify>
    <automated>grep -c "wait_for_dart_mapper" /home/angeloavv/FlutterProjects/dart_mapper/.github/workflows/publish.yml</automated>
  </verify>
  <done>
    - `wait_for_dart_mapper` job appears in publish.yml with `needs: dart_runner`, `runs-on: ubuntu-latest`, checkout step, and bash polling loop
    - `dart_mapper_generator` job has `needs: [wait_for_dart_mapper]` (no longer depends directly on `dart_runner`)
    - Polling loop reads version dynamically, retries 20 times with 30-second intervals, emits `::error::` annotation on timeout
  </done>
</task>

</tasks>

<verification>
After the task completes, verify the workflow structure is correct:
- `dart_runner` → `wait_for_dart_mapper` → `dart_mapper_generator` (linear chain)
- No job still depends on `dart_runner` for the generator path
- YAML syntax is valid (no parse errors)
</verification>

<success_criteria>
- `.github/workflows/publish.yml` contains the `wait_for_dart_mapper` job between `dart_runner` and `dart_mapper_generator`
- The polling loop dynamically resolves the version from `packages/dart_mapper/pubspec.yaml`
- `dart_mapper_generator` depends on `wait_for_dart_mapper`, not `dart_runner`
- The file is valid YAML
</success_criteria>

<output>
No SUMMARY.md required for quick tasks. Update `.planning/STATE.md` Quick Tasks Completed table with this task entry after completion.
</output>

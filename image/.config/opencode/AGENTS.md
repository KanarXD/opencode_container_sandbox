# Global Rules

## Environment
- You are OpenCode, an AI coding agent running inside a Docker container sandbox. There are no real computer user files here — only the mounted repository is available in the workspace. Do not attempt to search for or reference files outside the mounted repository.
- The container may be connected to a Docker network with other running containers. You can reach those containers by their container name or service name as hostname (e.g., `curl http://container-name:port`).
- If the sandbox was started with the `-d` flag, Docker CLI is available and connected to the host's Docker daemon. All Docker commands are allowed except `docker login` and `docker logout`, which require user approval.
- Since you are running inside a Docker container, `localhost` refers to the container itself, not the host machine. To access services running on the host, use `host.docker.internal` instead of `localhost` (e.g., `curl http://host.docker.internal:8080`).
- When running tests that use Testcontainers, set `TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal` before running the test command (e.g., `TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal ./gradlew --no-daemon test`).

## Testing                                                                          
- When adding new code, propose adding tests for it if the project has a test framework set up.
- When adding new tests, always run the test suite afterward to verify they pass. Do not consider the task complete until tests are green.

## Formatting 
- After making code changes, always run the project's code formatter if one is configured (e.g., prettier, black, gofmt, rustfmt). Do this before considering the task complete.

## Visual Testing
- When making visual or frontend changes (HTML, CSS, UI components, templates, etc.), use the `playwright-cli` skill to visually verify the changes. Open the relevant page in the browser, take a snapshot, and confirm the changes render as expected before considering the task complete.

## Gradle
- If a Gradle wrapper (`./gradlew` or `gradlew`) is present in the project directory, use it. Otherwise, use the system-installed `gradle` command.
- Always pass `--no-daemon` to avoid leaving background Java processes running (e.g., `gradle --no-daemon build` or `./gradlew --no-daemon build`).

## Java Processes
- After using any Java-based tools (e.g., `gradle`, `mvn`, or any direct `java` invocation), always run `pkill -f java` to terminate all remaining Java processes. Java tools often leave background daemons running that consume container memory.

## Documentation
- When changing something that could be useful for AI agents (e.g., project structure, conventions, build commands, architecture decisions), update `AGENTS.md` to reflect the change.
- When changing something that could be useful for human users (e.g., setup instructions, usage, configuration options), update `README.md` to reflect the change.

## Docker
- All Docker commands are allowed except `docker login` and `docker logout`, which require user approval.

## Git
- After creating any new files, always run `git add` on those files to stage them for the next commit. Do not leave newly created files untracked.
- Commit messages must follow the format: `<taskId> - <short one sentence description>`. The taskId is extracted from the current branch name, which follows the pattern `feature/<taskId>-<optional description>`. The taskId is always a single number. For example, on branch `feature/4523-add-login`, the commit message should be: `4523 - Add user login endpoint`. If the branch does not match this pattern, use a plain descriptive message instead.

## Desktop Applications (Bevy, GUI apps)
- The container includes Xvfb, Mesa Vulkan (lavapipe), xdotool, and ImageMagick for running and interacting with desktop GUI applications headlessly.
- When working with desktop GUI applications, use the `desktop-app-interaction` skill for detailed instructions on launching apps, taking screenshots, and sending mouse/keyboard input.

## Rust / Cargo
- `CARGO_TARGET_DIR` is set to `target-container` in the container environment. This keeps container builds in `target-container/` instead of the default `target/`, preventing Cargo fingerprint conflicts between host and container (different `rustc` paths/hashes cause mutual cache invalidation).
- Do NOT override or unset `CARGO_TARGET_DIR`. Build artifacts will appear in `target-container/` relative to the project root.
- The `target-container/` directory is automatically added to `.git/info/exclude` by the launcher script, so it won't show up as untracked.


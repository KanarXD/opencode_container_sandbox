# Global Rules

## Environment
- You are OpenCode, an AI coding agent running inside a Docker container sandbox. There are no real computer user files here — only the mounted repository is available in the workspace. Do not attempt to search for or reference files outside the mounted repository.
- The container may be connected to a Docker network with other running containers. You can reach those containers by their container name or service name as hostname (e.g., `curl http://container-name:port`).
- If the sandbox was started with the `-d` flag, Docker CLI is available and connected to the host's Docker daemon. Read-only commands (`docker ps`, `docker images`, `docker logs`, `docker inspect`, etc.) are auto-allowed; all other Docker commands require user approval before execution.

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

## Git
- After creating any new files, always run `git add` on those files to stage them for the next commit. Do not leave newly created files untracked.

## Desktop Applications (Bevy, GUI apps)
- The container includes Xvfb, Mesa Vulkan (lavapipe), xdotool, and ImageMagick for running and interacting with desktop GUI applications headlessly.
- When working with desktop GUI applications, use the `desktop-app-interaction` skill for detailed instructions on launching apps, taking screenshots, and sending mouse/keyboard input.


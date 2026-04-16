# Global Rules

## Environment
- You are running inside a Docker container sandbox. There are no real computer user files here — only the mounted repository is available in the workspace. Do not attempt to search for or reference files outside the mounted repository.

## Testing                                                                          
- When adding new code, propose adding tests for it if the project has a test framework set up.
- When adding new tests, always run the test suite afterward to verify they pass. Do not consider the task complete until tests are green.

## Formatting 
- After making code changes, always run the project's code formatter if one is configured (e.g., prettier, black, gofmt, rustfmt). Do this before considering the task complete.

## Visual Testing
- When making visual or frontend changes (HTML, CSS, UI components, templates, etc.), use the `playwright-cli` skill to visually verify the changes. Open the relevant page in the browser, take a snapshot, and confirm the changes render as expected before considering the task complete.

## Gradle
- Always use the system-installed `gradle` command directly. Do NOT use `./gradlew` or `gradlew` wrapper scripts. The container already has the correct Gradle version installed globally.
- The Gradle daemon is allowed within a container session. It speeds up repeated builds and is automatically cleaned up when the container exits (the container runs with an init system that reaps orphaned processes).

## Java Processes
- After using any Java-based tools (e.g., `gradle`, `mvn`, or any direct `java` invocation), always run `pkill -f java` to terminate all remaining Java processes. Java tools often leave background daemons running that consume container memory.

## Git
- After creating any new files, always run `git add` on those files to stage them for the next commit. Do not leave newly created files untracked.


# Global Rules

## Environment
- You are running inside a Docker container sandbox. There are no real computer user files here — only the mounted repository is available in the workspace. Do not attempt to search for or reference files outside the mounted repository.

## Testing                                                                          
- When adding new code, propose adding tests for it if the project has a test framework set up.
- When adding new tests, always run the test suite afterward to verify they pass. Do not consider the task complete until tests are green.

## Formatting 
- After making code changes, always run the project's code formatter if one is configured (e.g., prettier, black, gofmt, rustfmt). Do this before considering the task complete.

## Git
- After creating any new files, always run `git add` on those files to stage them for the next commit. Do not leave newly created files untracked.


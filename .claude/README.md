# Claude Code Configuration

This directory contains Claude Code configurations for iOS development.

## Structure

```
.claude/
├── agents/          # Custom subagents for specialized tasks
│   ├── swift-architect.md
│   ├── test-engineer.md
│   ├── ui-polish.md
│   └── performance-optimizer.md
├── commands/        # Custom slash commands for common tasks
│   ├── run.md
│   ├── test.md
│   ├── implement-phase.md
│   ├── refactor.md
│   └── add-tests.md
├── skills/          # Automatically-invoked task patterns
│   ├── xcode-swift-build.md
│   ├── swift-refactoring.md
│   ├── swiftui-patterns.md
│   └── swift-concurrency-best-practices.md
├── settings.json    # Hooks configuration
├── activity.log     # Session activity log (auto-generated)
└── README.md

../.mcp.json         # MCP server configuration (project root)
../<AppName>.xcodeproj  # Xcode project file
```

## Subagents

Subagents are specialized AI assistants for specific tasks. Invoke them explicitly when needed.

### swift-architect
**When to use**: Designing architecture, refactoring, making structural decisions

**Expertise**:
- Clean architecture (UI, Domain, Data layers)
- Swift best practices (async/await, protocols, value types)
- SwiftUI patterns for iOS
- MVVM and state management with @Observable

**Example**: "Use the swift-architect subagent to design the data persistence layer"

### test-engineer
**When to use**: Writing tests, improving coverage, debugging test failures

**Expertise**:
- XCTest framework
- Swift Testing (modern testing framework)
- Arrange-Act-Assert pattern
- Async/await testing with Swift Concurrency
- Test-driven development

**Example**: "Use the test-engineer subagent to add unit tests for the data model"

### ui-polish
**When to use**: Improving UI/UX, adding animations, accessibility

**Expertise**:
- SwiftUI and iOS design guidelines (Human Interface Guidelines)
- Smooth animations and transitions
- Touch gestures and navigation patterns
- Visual design and color theory
- Accessibility with VoiceOver and Dynamic Type

**Example**: "Use the ui-polish subagent to improve the onboarding flow animations"

### performance-optimizer
**When to use**: Profiling, optimizing performance, reducing memory usage

**Expertise**:
- Swift performance tuning and Instruments profiling
- Swift Concurrency optimization (actor isolation, task groups)
- Algorithm efficiency analysis
- SwiftUI view update optimization

**Example**: "Use the performance-optimizer subagent to optimize list scrolling performance"

## Skills

Skills are automatically invoked by Claude based on the task context. You don't need to explicitly request them.

### xcode-swift-build
**Auto-invoked when**: Building, testing, or packaging the project

**Provides**:
- Common xcodebuild commands
- Build troubleshooting steps
- Error resolution guidance
- Archive and distribution commands

### swift-refactoring
**Auto-invoked when**: Refactoring Swift code

**Provides**:
- Project design principles (minimize complexity, deep modules)
- Before/after refactoring examples
- Protocols, extensions, value types patterns
- Refactoring checklist

### swiftui-patterns
**Auto-invoked when**: Working with SwiftUI

**Provides**:
- State management with @State, @Observable, @Binding
- Animation patterns (withAnimation, transitions)
- Performance optimization (@ViewBuilder, identity)
- Touch gestures and focus handling
- Common layouts (NavigationStack, TabView, sheets, alerts)

### swift-concurrency-best-practices
**Auto-invoked when**: Working with Swift Concurrency

**Provides**:
- Task and actor patterns
- Structured concurrency (async let, TaskGroup)
- Main actor isolation for UI updates
- AsyncSequence for progress reporting
- Cancellation support and error handling

## Hooks

Hooks are automated commands that run at specific points in Claude Code's workflow.

### Configured Hooks (`.claude/settings.json`)

#### PostToolUse (After Write/Edit)
Automatically formats Swift code after any file write or edit:
- Runs `swift-format` or `swiftformat` to format code
- Can be configured with `.swift-format` configuration file
- Timeout: 30 seconds

#### PreToolUse (Before Build)
Displays a notification before running builds:
- Shows "Building project..." message
- Helps track when builds are triggered

#### UserPromptSubmit (Every User Message)
Logs user activity for session tracking:
- Timestamps each user prompt
- Logs saved to `.claude/activity.log`

#### SessionStart (New Session)
Logs when a Claude Code session begins:
- Records session start time
- Helps track development sessions

### Benefits

- **Automatic formatting**: Never commit unformatted code
- **Activity tracking**: Review your development sessions
- **Build awareness**: Know when long operations start
- **Consistency**: Enforces project code style automatically

### Customizing Hooks

Edit `.claude/settings.json` to add or modify hooks. See [Hooks Guide](https://code.claude.com/docs/en/hooks-guide) for more options.

## Slash Commands

Custom slash commands provide quick access to common development tasks.

### /run
Run the iOS application in the simulator.

```
/run
```

### /test
Run all tests or a specific test.

```
/test                    # Run all tests
/test DataModelTests     # Run specific test
```

### /refactor
Refactor code following project design principles.

```
/refactor Sources/<AppName>/DataModel.swift
/refactor the network service to use protocols
```

Uses the swift-architect subagent and applies:
- Minimize complexity
- Protocol-oriented design
- Extension functions
- Value type patterns

### /add-tests
Add comprehensive tests for a component or feature.

```
/add-tests DataModel
/add-tests Sources/<AppName>/Domain/User.swift
```

Uses the test-engineer subagent to write:
- Happy path tests
- Edge case tests
- Error handling tests
- Async/await tests (if applicable)

## MCP Servers

MCP (Model Context Protocol) servers provide additional capabilities to Claude Code.

### Configured Servers (`.mcp.json`)

#### filesystem
- **Purpose**: File system access for the project directory
- **Usage**: Automatically available for file operations

#### github
- **Purpose**: GitHub integration (issues, PRs, repository management)
- **Setup**: Requires `GITHUB_TOKEN` environment variable
- **Usage**: Fetch issue details, create PRs, query repository data

#### jetbrains
- **Purpose**: IntelliJ IDEA integration for code intelligence and navigation
- **Setup**: Install the MCP plugin in IntelliJ and restart the IDE
- **Usage**: Automatically connects to running IntelliJ instance on port 64342

### Setting up GitHub MCP
```bash
# Add your GitHub token to your shell profile
export GITHUB_TOKEN="your_personal_access_token"
```

## How to Use This Configuration

### Quick Tasks (Use Slash Commands)
```
/run                       # Run the app in simulator
/test                      # Run tests
/refactor NetworkService   # Refactor with design principles
/add-tests DataModel       # Add comprehensive tests
```

### General Development (Skills Auto-Activate)
Just work normally - skills are automatically invoked as needed:
- Building/testing → `xcode-swift-build` skill activates
- Writing async/await → `swift-concurrency-best-practices` skill activates
- Creating UI → `swiftui-patterns` skill activates
- Refactoring → `swift-refactoring` skill activates

### Specialized Tasks (Invoke Subagents)
Explicitly invoke subagents for expert guidance:
```
"Use the swift-architect subagent to help design the Core Data model"
"Use the test-engineer subagent to create integration tests for API calls"
"Use the ui-polish subagent to improve the tab bar navigation"
"Use the performance-optimizer subagent to profile and optimize image loading"
```

### Complex Workflows (Combine Everything)
1. Manually combine: swift-architect → implement → test-engineer → performance-optimizer → ui-polish
2. Use `/refactor` to apply design principles
3. Use `/add-tests` to ensure coverage
4. Use `/test` to verify everything works

## Customization

### Adding New Commands
1. Create `.claude/commands/your-command.md`
2. Add YAML frontmatter with `description`, `allowed-tools`, `argument-hint`
3. Write markdown with command instructions using `$ARGUMENTS` or `$1`, `$2` for arguments
4. Reference files with `@filename.md` syntax

### Adding New Skills
1. Create `.claude/skills/your-skill-name.md`
2. Add YAML frontmatter with `name` and `description`
3. Write markdown content with patterns and examples

### Adding New Subagents
1. Create `.claude/agents/your-agent-name.md`
2. Add YAML frontmatter with `name`, `description`, `tools`, `model`
3. Write system prompt with expertise and guidelines

### Adding MCP Servers
1. Edit `.mcp.json` in project root
2. Add server configuration with type, command, args
3. Restart Claude Code to load new server

## Best Practices

1. **Let skills work automatically** - Don't explicitly invoke them
2. **Use subagents for expertise** - They have specialized knowledge
3. **Follow iOS Human Interface Guidelines** - Ensure native iOS feel
4. **Iterate** - Use multiple agents for complex tasks
5. **Test on device** - Simulator doesn't match real device performance

## References

- [Claude Code MCP Documentation](https://code.claude.com/docs/en/mcp)
- [Subagents Documentation](https://code.claude.com/docs/en/sub-agents)
- [Skills Documentation](https://code.claude.com/docs/en/skills)
- [Slash Commands Documentation](https://code.claude.com/docs/en/slash-commands)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)

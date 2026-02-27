# Workflow Details

## Session Recording Workflow

### Starting a Session

```
1. Check current project context
2. Create session note:
   - Path: AI-Sessions/YYYY-MM-DD-{project}.md
   - Use template from Templates/session.md
   - Fill in: date, project name, initial goals
3. Link session to project page:
   - Add to Projects/{project}/_Index.md → Sessions section
```

### During Session

```
1. Update Progress section:
   - Move items from "In Progress" to "Completed"
   - Add new discoveries to "Discoveries"
2. Record changes:
   - Add to "Changes Made" table
   - Format: | file | type | description |
3. Add knowledge notes:
   - If reusable knowledge found, create Knowledge/{category}/{topic}.md
   - Link from session note
```

### Ending a Session

```
1. Review and summarize:
   - Ensure Progress accurately reflects work done
   - Update "Next Steps" with actionable items
2. Update MOC:
   - Add session to AI-Sessions/_Index.md
   - Update project page if needed
3. Create follow-up:
   - If continuation needed, note in "Next Steps"
```

## Knowledge Management Workflow

### Searching Knowledge

```
1. Use obsidian search with relevant keywords
2. If found:
   - Read note with obsidian read
   - Reference in current session
3. If not found:
   - Create new knowledge note with obsidian write --create
   - Link to relevant projects/sessions
```

### Adding Knowledge

```
1. Determine category:
   - iOS-Development, Architecture, Swift, Tools, AI-Agent
2. Create note:
   - Path: Knowledge/{category}/{topic}.md
   - Use template from Templates/knowledge.md
3. Add links:
   - Link to source session
   - Link to related knowledge
   - Update Knowledge/_Index.md
```

## Project Documentation Workflow

### New Project Setup

```
1. Create project directory:
   - Projects/{project-name}/
2. Create index:
   - Projects/{project-name}/_Index.md
   - Use template from Templates/project.md
3. Add to MOC:
   - Update Projects/_Index.md
```

### Updating Project

```
1. After significant sessions, update:
   - Architecture section (if changed)
   - Key Files (if new important files)
   - Related Knowledge (if new discoveries)
2. Keep Sessions section current
```

## Linking Strategy

### Internal Links (Obsidian [[]] syntax)

```markdown
- Projects: [[Projects/{project}/_Index|{project}]]
- Sessions: [[AI-Sessions/YYYY-MM-DD-{project}|Session Date]]
- Knowledge: [[Knowledge/{category}/{topic}|Topic Name]]
```

### External File Links

```markdown
- Code files: `file:///path/to/file.swift`
- Directories: `file:///path/to/directory/`
```

### Tags

Standard tags:
- #session - セッション記録
- #project - プロジェクトページ
- #knowledge - 技術ノート
- #planning - 計画関連
- #implementation - 実装関連
- #debugging - デバッグ関連
- #refactoring - リファクタリング

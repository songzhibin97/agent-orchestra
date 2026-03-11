# Conflict Resolution

Defines how to handle contradictory information from multiple providers.

## When Conflicts Occur

A conflict exists when two or more sources give incompatible answers about:
- API behavior or return values
- Correct usage of a library or tool
- Whether a bug is fixed in a specific version
- Configuration options or defaults

## Resolution Priority

Resolve by applying these criteria in order:

### 1. Authority Level
Higher-authority sources win over lower-authority sources.

Authority order (highest to lowest):
1. Official documentation from the package/tool maintainer
2. Official GitHub issues/releases from the maintainer
3. Authoritative community sources (Stack Overflow accepted answers, major blogs)
4. General web search results

### 2. Version Specificity
When authority is equal, prefer the answer that matches the exact version in use.

- Check the repo's `package.json`, `go.mod`, `requirements.txt`, etc. for the installed version.
- A source that answers for version 2.1.0 is more reliable than one for "2.x" when the installed version is 2.1.0.

### 3. Publication Date
When authority and version specificity are equal, prefer the more recently published source.

- More recent sources are more likely to reflect current behavior after bug fixes or breaking changes.

## Reporting Format

When a conflict is detected, report it explicitly:

```md
Conflict detected:
- Source A (<url or file>): <claim A>
- Source B (<url or file>): <claim B>
Resolution: Selected <A|B> because <reason from priority criteria above>
Confidence: HIGH | MEDIUM | LOW
```

## Low Confidence Handling

If the conflict cannot be resolved clearly:

- Label the selected answer as `HYPOTHESIS`.
- Add: `"Needs manual verification — run <specific test command> to confirm."`
- Do not present a HYPOTHESIS as fact in the `Next steps` output.

## When Both Sources May Be Correct

Some conflicts are version-specific: one source is correct for an older version, another for a newer one. In this case:
- Report the version boundary explicitly.
- Recommend checking the changelog between the two versions.

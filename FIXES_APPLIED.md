# Fixes Applied — Ketion Block-Tree, Numbered-List & PDF Export

This document details the targeted fixes applied to Ketion for block-tree reconstruction, numbered-list ordering, toggle visibility, and PDF export. All changes preserve the existing SQLite-backed block model and use the project's documented `parentBlockId` + `position` hierarchy.

---

## Issue 1 — Toggle Hides Only Some Child Blocks & PDF Export

### Root Cause
1. **Incomplete Subtree Hiding**: In `BlockTreeService.buildVisibleTree()`, descendants were traversed regardless of the toggle's `isExpanded` state. While the toggle header could change its arrow state, child blocks remained in the flattened list and were rendered.
2. **PDF Export Leaking Collapsed Children**: `ExportUseCase._mapToDocument()` previously appended unvisited blocks after processing the visible tree. That fallback re-added descendants that had been hidden by a collapsed toggle, causing them to appear as standalone PDF items. Furthermore, the PDF exporter lacked disclosure marker differentiation between expanded and collapsed toggles.

### Fixes Applied
- **`lib/features/editor/domain/services/block_tree_service.dart`**:
  - `buildVisibleTree()` now checks the toggle's expansion state (`isExpanded`).
  - When a toggle is collapsed (`!expanded`), `markSubtreeHidden` recursively marks all descendants as visited in the traversal set. This hides the entire descendant subtree (paragraphs, headings, lists, checklists, images, videos, nested toggles) while preventing them from reappearing through orphan recovery loops.
  - Sibling blocks remain sorted deterministically by `position` and preorder is preserved when expanded. Collapsing is purely a visibility operation without altering database records or `parentBlockId`.
- **`lib/features/import_export/domain/usecases/export_usecase.dart`**:
  - Export now consumes `BlockTreeService.buildVisibleTree(blocks)` directly without appending unvisited blocks, preventing collapsed children from leaking into exports.
  - For toggle blocks, the export mapping passes `toggle_expanded` or `toggle` based on `listBlock.isExpanded`, enabling disclosure marker state propagation without modifying persisted database schema.
- **`lib/features/import_export/domain/services/pdf_exporter.dart`**:
  - Updated toggle marker drawing in `PdfExporter`: renders a downward triangle for expanded toggles (`toggle_expanded`) and a right-pointing triangle for collapsed toggles (`toggle`).
  - Preserved toggle headers even when empty so toggle hierarchy remains intact in exports.

---

## Issue 2 — Numbered-List Swipe Indentation Visually Inconsistent

### Root Cause
1. **Visual Indentation Mismatch**: In `depth_wrapping_component_builder.dart`, `kIndentPerLevel` was set to `16.0` pixels, whereas the component prefix spacing used `24.0` pixels.
2. **Transient Indent Priority**: `getNodeDepth()` prioritized the transient Super Editor `indent` property over persisted `metadata['depth']`. After restoring or converting a node, those values could temporarily disagree, causing number and text to appear at mismatched indentation levels.

### Fixes Applied
- **`lib/features/editor/presentation/widgets/depth_wrapping_component_builder.dart`**:
  - Updated `getNodeDepth()` to prioritize persisted structural depth (`metadata['depth']`), clamped to `[0, 99]`, falling back to `node.indent.clamp(0, 99)` for `ListItemNode` and `TaskNode`.
  - Updated `kIndentPerLevel` from `16.0` to `24.0`, ensuring visual indentation per level is consistent across numbered lists, components, and export.

---

## Issue 3 — Numbered-List Sequencing & Checklist Strikethrough

### Fixes Applied
- **`lib/features/editor/presentation/widgets/ketion_list_item_component.dart`**:
  - Sibling parent comparison recognizes `null` as a distinct root-parent identity, preventing ordinal numbering from leaking across branches or between root and nested lists.
- **`lib/features/import_export/domain/services/pdf_exporter.dart`**:
  - Applied `pw.TextDecoration.lineThrough` with `PdfColors.grey700` and `0.8` thickness to checked checklist text in PDF exports.

---

---

## Issue 4 — Multi-Format Export Hierarchy & Interactive Toggles

### Root Cause
1. **Markdown Exporter Flattening**: `MarkdownExporter` previously ignored `depth` on list items, output all lists as flat bullets `- `, and lacked toggle disclosure markers.
2. **HTML Exporter Lacking Collapsible Semantics**: `HtmlExporter` rendered all lists as `<ul>` (ignoring numbered lists) and output toggles as plain bullet items without interactive HTML `<details>` / `<summary>` tags.
3. **PDF Exporter Rich-Text Stripping**: `PdfExporter` stripped `DocumentTextSpan` styling (bold, italic, code, underline, strikethrough, links) down to plain strings, and lacked sanitization for Unicode characters (emojis, smart quotes, bullets) that are unsupported by standard PDF Type-1 fonts.

### Fixes Applied
- **`lib/features/import_export/domain/services/markdown_exporter.dart`**:
  - Implemented 2-space depth indentation per level for all list types, paragraphs, code blocks, and callouts.
  - Formatted numbered lists with ordered list syntax (`1.`) and checklists with GFM syntax (`- [ ]`, `- [x]`).
  - Represented expanded and collapsed toggles with standard `- ▾` and `- ▸` markers.
- **`lib/features/import_export/domain/services/html_exporter.dart`**:
  - Rendered toggles using semantic, accessible `<details class="ketion-toggle"${isExpanded ? ' open' : ''}>` and `<summary>` tags with automatic depth-aware closing.
  - Differentiated between `<ol>` for numbered lists and `<ul>` for bullet and checklist items.
  - Added checklist item styling (`class="checklist-item"`) with strikethrough decoration on completed items.
- **`lib/features/import_export/domain/services/pdf_exporter.dart`**:
  - Implemented `_spansToPdfWidget` using `pw.RichText` and `pw.TextSpan` to preserve bold, italic, code background, underline, strikethrough, and links in paragraphs, headings, and lists.
  - Added `_sanitizeTextForPdf` to safely map high-Unicode emojis (⏰, 💡, 📌, ⚠️), smart quotes, and bullets to encodable ASCII representations, preventing font encoding exceptions.
- **`test/features/editor/toggle_hierarchy_roundtrip_test.dart`**:
  - Added end-to-end integration test verifying tree filtering, cycle protection, and export fidelity across PDF, HTML, and Markdown.

---

## Summary of Changes

| File | Change |
| ---- | ------ |
| `lib/features/editor/domain/services/block_tree_service.dart` | Hide all descendants of collapsed toggles while retaining their data; protect tree traversal against cyclic references |
| `lib/features/import_export/domain/usecases/export_usecase.dart` | Prevent hidden descendants from leaking into exports; normalize legacy toggle records; carry parentKey into export models |
| `lib/features/import_export/domain/services/pdf_exporter.dart` | Render rich-text spans; group toggle children with visual guide borders; draw disclosure markers; sanitize unicode glyphs |
| `lib/features/import_export/domain/services/markdown_exporter.dart` | Support hierarchical depth indentation, ordered lists, and toggle state indicators |
| `lib/features/import_export/domain/services/html_exporter.dart` | Output interactive `<details>` / `<summary>` toggles, ordered lists, and styled checklist items |
| `lib/features/editor/presentation/widgets/depth_wrapping_component_builder.dart` | Use persisted depth, consistent 24 px indentation, and horizontal drag preview |
| `lib/features/editor/presentation/widgets/ketion_slash_command_registry.dart` | Inherit placement metadata for dividers, tables, and media blocks |
| `test/features/import_export/markdown_and_html_exporter_test.dart` | Add test suite for Markdown and HTML export formatting |
| `test/features/editor/toggle_hierarchy_roundtrip_test.dart` | Add end-to-end integration test for toggle lifecycle and multi-format export |
| `FIXES_APPLIED.md` | Document changes, root causes, and verification tests |

---

## Verification Instructions

Run the test suites and analyzer:

```bash
flutter test test/features/import_export/markdown_and_html_exporter_test.dart
flutter test test/features/import_export/pdf_exporter_test.dart
flutter test test/features/editor/toggle_hierarchy_roundtrip_test.dart
flutter analyze
```

### Test Checklist
- Collapse a toggle containing paragraphs, headings, bullets, numbered lists, checklists, images, and videos. Confirm all descendants disappear.
- Expand the toggle and confirm every child returns in the correct order.
- Export a toggle to HTML and confirm it renders as an interactive `<details>` element with `<summary>`.
- Export a nested toggle to Markdown and confirm indentation and toggle markers reflect the hierarchy.
- Export a page with emojis, rich text formatting, and nested toggles to PDF and confirm valid generation without font exceptions.
- Swipe a numbered item to indent and outdent it. Confirm the number and text move together with live preview.

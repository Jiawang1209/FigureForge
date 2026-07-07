# FigureForge Skill + MCP Dual-Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build FigureForge into a dual-layer product with an agent-facing skill layer and a local MCP server exposing case discovery, inspection, validation, indexing, rendering, and mapping helpers.

**Architecture:** Keep `skills/figureforge/` as the reasoning and workflow layer. Add a TypeScript MCP package under `mcp/figureforge/` that reads local case metadata, wraps existing R scripts, and returns structured tool results. Use fixtures for tests so the public implementation does not depend on the private 166-case corpus.

**Tech Stack:** Markdown, TypeScript, Node.js, MCP SDK, Zod, Vitest, Rscript, existing FigureForge R helper scripts.

---

## File Structure

- Create: `mcp/figureforge/package.json`  
  Defines the local MCP server package, scripts, dependencies, and bin entry.

- Create: `mcp/figureforge/tsconfig.json`  
  TypeScript build configuration.

- Create: `mcp/figureforge/src/index.ts`  
  MCP server entrypoint and tool registration.

- Create: `mcp/figureforge/src/config.ts`  
  FigureForge root discovery and path configuration.

- Create: `mcp/figureforge/src/types.ts`  
  Shared case metadata and tool result types.

- Create: `mcp/figureforge/src/caseParser.ts`  
  Markdown `case.md` section parser.

- Create: `mcp/figureforge/src/caseStore.ts`  
  Case discovery, listing, lookup, and search.

- Create: `mcp/figureforge/src/rScripts.ts`  
  Safe wrappers around existing R helper scripts.

- Create: `mcp/figureforge/src/tools/*.ts`  
  One focused file per MCP tool.

- Create: `mcp/figureforge/tests/fixtures/cases/*`  
  Small redistributable test cases.

- Create: `mcp/figureforge/tests/*.test.ts`  
  Unit tests for parsing, search, config, and tool behavior.

- Modify: `skills/figureforge/SKILL.md`  
  Add a short MCP usage section while preserving direct file/script fallback.

- Modify: `README.md` and `README.zh.md`  
  Add the Skill + MCP dual-layer roadmap after the MCP server exists.

## Task 1: Scaffold the MCP Package

**Files:**
- Create: `mcp/figureforge/package.json`
- Create: `mcp/figureforge/tsconfig.json`
- Create: `mcp/figureforge/src/index.ts`
- Create: `mcp/figureforge/src/config.ts`
- Create: `mcp/figureforge/src/types.ts`
- Test: `mcp/figureforge/tests/config.test.ts`

- [ ] **Step 1: Create the package directories**

Run:

```bash
mkdir -p mcp/figureforge/src mcp/figureforge/tests
```

Expected: directories exist.

- [ ] **Step 2: Write `package.json`**

Create `mcp/figureforge/package.json`:

```json
{
  "name": "@figureforge/mcp-server",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "bin": {
    "figureforge-mcp": "dist/index.js"
  },
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "test": "vitest run",
    "dev": "tsx src/index.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "tsx": "^4.19.0",
    "typescript": "^5.5.0",
    "vitest": "^2.0.0"
  }
}
```

- [ ] **Step 3: Write `tsconfig.json`**

Create `mcp/figureforge/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*.ts"],
  "exclude": ["dist", "node_modules", "tests"]
}
```

- [ ] **Step 4: Write a failing config test**

Create `mcp/figureforge/tests/config.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { discoverFigureForgeRoot } from "../src/config.js";

describe("discoverFigureForgeRoot", () => {
  it("uses FIGUREFORGE_ROOT when it points at a FigureForge checkout", () => {
    const root = process.cwd().replace(/\/mcp\/figureforge$/, "");
    const found = discoverFigureForgeRoot({ env: { FIGUREFORGE_ROOT: root }, cwd: "/tmp" });
    expect(found.root).toBe(root);
    expect(found.skillPath.endsWith("skills/figureforge/SKILL.md")).toBe(true);
  });
});
```

- [ ] **Step 5: Run the test and verify it fails**

Run:

```bash
cd mcp/figureforge && npm test -- config.test.ts
```

Expected: FAIL because `src/config.ts` is not implemented.

- [ ] **Step 6: Implement shared types**

Create `mcp/figureforge/src/types.ts`:

```ts
export type FigureForgeConfig = {
  root: string;
  skillPath: string;
  casesDir: string;
  scriptsDir: string;
  referencesDir: string;
  outputDir: string;
};

export type CaseMetadata = {
  caseId: string;
  title: string;
  chartType: string;
  chartTypeZh: string;
  aliases: string;
  bestFor: string;
  bestForZh: string;
  dataSchema: string;
  visualEncoding: string;
  ggplotComponents: string;
  adaptationNotes: string;
  commonPitfalls: string;
  caseDir: string;
};

export type ToolError = {
  ok: false;
  message: string;
  detail?: string;
};

export type ToolSuccess<T> = {
  ok: true;
  data: T;
};

export type ToolResult<T> = ToolSuccess<T> | ToolError;
```

- [ ] **Step 7: Implement root discovery**

Create `mcp/figureforge/src/config.ts`:

```ts
import { existsSync } from "node:fs";
import path from "node:path";
import type { FigureForgeConfig } from "./types.js";

type DiscoveryInput = {
  env?: NodeJS.ProcessEnv;
  cwd?: string;
};

function buildConfig(root: string): FigureForgeConfig {
  return {
    root,
    skillPath: path.join(root, "skills", "figureforge", "SKILL.md"),
    casesDir: path.join(root, "skills", "figureforge", "cases"),
    scriptsDir: path.join(root, "skills", "figureforge", "scripts"),
    referencesDir: path.join(root, "skills", "figureforge", "references"),
    outputDir: path.join(root, "outputs", "figureforge")
  };
}

function isFigureForgeRoot(root: string): boolean {
  return existsSync(path.join(root, "skills", "figureforge", "SKILL.md"));
}

export function discoverFigureForgeRoot(input: DiscoveryInput = {}): FigureForgeConfig {
  const env = input.env ?? process.env;
  const cwd = input.cwd ?? process.cwd();
  const envRoot = env.FIGUREFORGE_ROOT;

  if (envRoot && isFigureForgeRoot(envRoot)) {
    return buildConfig(envRoot);
  }

  if (isFigureForgeRoot(cwd)) {
    return buildConfig(cwd);
  }

  const parent = path.resolve(cwd, "..", "..");
  if (isFigureForgeRoot(parent)) {
    return buildConfig(parent);
  }

  throw new Error("FigureForge root not found. Set FIGUREFORGE_ROOT to the repository root.");
}
```

- [ ] **Step 8: Add a minimal MCP entrypoint**

Create `mcp/figureforge/src/index.ts`:

```ts
#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { discoverFigureForgeRoot } from "./config.js";

const config = discoverFigureForgeRoot();

const server = new McpServer({
  name: "figureforge",
  version: "0.1.0"
});

server.tool("figureforge_health", {}, async () => ({
  content: [
    {
      type: "text",
      text: JSON.stringify(
        {
          ok: true,
          root: config.root,
          casesDir: config.casesDir,
          scriptsDir: config.scriptsDir
        },
        null,
        2
      )
    }
  ]
}));

const transport = new StdioServerTransport();
await server.connect(transport);
```

- [ ] **Step 9: Run tests and build**

Run:

```bash
cd mcp/figureforge && npm install && npm test && npm run build
```

Expected: tests pass and TypeScript builds.

- [ ] **Step 10: Commit**

Run:

```bash
git add mcp/figureforge/package.json mcp/figureforge/tsconfig.json mcp/figureforge/src mcp/figureforge/tests
git commit -m "feat: scaffold FigureForge MCP server"
```

## Task 2: Parse and Discover Cases

**Files:**
- Create: `mcp/figureforge/src/caseParser.ts`
- Create: `mcp/figureforge/src/caseStore.ts`
- Create: `mcp/figureforge/tests/fixtures/cases/valid-bubble/case.md`
- Create: `mcp/figureforge/tests/fixtures/cases/valid-bubble/data.csv`
- Create: `mcp/figureforge/tests/fixtures/cases/valid-bubble/plot.R`
- Test: `mcp/figureforge/tests/caseParser.test.ts`
- Test: `mcp/figureforge/tests/caseStore.test.ts`

- [ ] **Step 1: Create a valid fixture case**

Run:

```bash
mkdir -p mcp/figureforge/tests/fixtures/cases/valid-bubble
```

Create `mcp/figureforge/tests/fixtures/cases/valid-bubble/case.md`:

```markdown
# Case valid-bubble: Demo Bubble Plot

## Chart Type
bubble plot

## Chart Type Chinese
气泡图

## Aliases
bubble plot, enrichment bubble, 气泡图, 富集气泡图

## Best For
Showing ranked categories with size and color encoding two metrics.

## Best For Chinese
适合展示富集条目或分类条目，并用气泡大小和颜色表达两个指标。

## Data Schema
`data.csv` columns: term, group, score, count.

## Visual Encoding
Y encodes term; X encodes group; size encodes count; color encodes score.

## ggplot Components
geom_point, scale_color_viridis_c, theme_minimal

## Adaptation Notes
Replace `data.csv` with real enrichment output while preserving the same columns.

## Common Pitfalls
Check factor ordering and keep labels short enough for export.
```

Create `mcp/figureforge/tests/fixtures/cases/valid-bubble/data.csv`:

```csv
term,group,score,count
Pathway_A,GO_BP,3.2,12
Pathway_B,GO_MF,4.1,20
Pathway_C,KEGG,2.8,9
```

Create `mcp/figureforge/tests/fixtures/cases/valid-bubble/plot.R`:

```r
#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "output.png"
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Missing ggplot2")
data <- read.csv(input_path, check.names = FALSE)
p <- ggplot2::ggplot(data, ggplot2::aes(x = group, y = term, size = count, color = score)) +
  ggplot2::geom_point() +
  ggplot2::theme_minimal()
ggplot2::ggsave(output_path, p, width = 5, height = 4, dpi = 150)
```

- [ ] **Step 2: Write parser tests**

Create `mcp/figureforge/tests/caseParser.test.ts`:

```ts
import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { parseCaseMarkdown } from "../src/caseParser.js";

describe("parseCaseMarkdown", () => {
  it("extracts English and Chinese case metadata", () => {
    const caseDir = path.join(process.cwd(), "tests/fixtures/cases/valid-bubble");
    const markdown = readFileSync(path.join(caseDir, "case.md"), "utf8");
    const parsed = parseCaseMarkdown("valid-bubble", caseDir, markdown);

    expect(parsed.caseId).toBe("valid-bubble");
    expect(parsed.title).toBe("Case valid-bubble: Demo Bubble Plot");
    expect(parsed.chartType).toBe("bubble plot");
    expect(parsed.chartTypeZh).toBe("气泡图");
    expect(parsed.aliases).toContain("富集气泡图");
    expect(parsed.dataSchema).toContain("term");
  });
});
```

- [ ] **Step 3: Run parser test and verify it fails**

Run:

```bash
cd mcp/figureforge && npm test -- caseParser.test.ts
```

Expected: FAIL because `caseParser.ts` does not exist.

- [ ] **Step 4: Implement Markdown parsing**

Create `mcp/figureforge/src/caseParser.ts`:

```ts
import type { CaseMetadata } from "./types.js";

function extractSection(markdown: string, heading: string): string {
  const lines = markdown.split(/\r?\n/);
  const start = lines.findIndex((line) => line.trim() === heading);
  if (start === -1) return "";

  const body: string[] = [];
  for (let index = start + 1; index < lines.length; index += 1) {
    if (lines[index].startsWith("## ")) break;
    body.push(lines[index].trim());
  }
  return body.filter(Boolean).join(" ").trim();
}

export function parseCaseMarkdown(caseId: string, caseDir: string, markdown: string): CaseMetadata {
  const firstHeading = markdown.split(/\r?\n/).find((line) => line.startsWith("# "));
  const title = firstHeading ? firstHeading.replace(/^#\s+/, "").trim() : caseId;

  return {
    caseId,
    title,
    chartType: extractSection(markdown, "## Chart Type"),
    chartTypeZh: extractSection(markdown, "## Chart Type Chinese"),
    aliases: extractSection(markdown, "## Aliases"),
    bestFor: extractSection(markdown, "## Best For"),
    bestForZh: extractSection(markdown, "## Best For Chinese"),
    dataSchema: extractSection(markdown, "## Data Schema"),
    visualEncoding: extractSection(markdown, "## Visual Encoding"),
    ggplotComponents: extractSection(markdown, "## ggplot Components"),
    adaptationNotes: extractSection(markdown, "## Adaptation Notes"),
    commonPitfalls: extractSection(markdown, "## Common Pitfalls"),
    caseDir
  };
}
```

- [ ] **Step 5: Write case store tests**

Create `mcp/figureforge/tests/caseStore.test.ts`:

```ts
import path from "node:path";
import { describe, expect, it } from "vitest";
import { CaseStore } from "../src/caseStore.js";

describe("CaseStore", () => {
  const casesDir = path.join(process.cwd(), "tests/fixtures/cases");

  it("lists parsed cases", () => {
    const store = new CaseStore(casesDir);
    const cases = store.listCases();
    expect(cases).toHaveLength(1);
    expect(cases[0].caseId).toBe("valid-bubble");
  });

  it("searches Chinese aliases", () => {
    const store = new CaseStore(casesDir);
    const matches = store.searchCases("富集气泡图", 10);
    expect(matches[0].caseId).toBe("valid-bubble");
  });

  it("gets one case by id", () => {
    const store = new CaseStore(casesDir);
    expect(store.getCase("valid-bubble")?.chartType).toBe("bubble plot");
  });
});
```

- [ ] **Step 6: Implement case store**

Create `mcp/figureforge/src/caseStore.ts`:

```ts
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { parseCaseMarkdown } from "./caseParser.js";
import type { CaseMetadata } from "./types.js";

export class CaseStore {
  constructor(private readonly casesDir: string) {}

  listCases(): CaseMetadata[] {
    if (!existsSync(this.casesDir)) return [];

    return readdirSync(this.casesDir)
      .map((name) => path.join(this.casesDir, name))
      .filter((caseDir) => statSync(caseDir).isDirectory())
      .filter((caseDir) => path.basename(caseDir) !== "_template")
      .map((caseDir) => {
        const caseId = path.basename(caseDir);
        const casePath = path.join(caseDir, "case.md");
        if (!existsSync(casePath)) return undefined;
        return parseCaseMarkdown(caseId, caseDir, readFileSync(casePath, "utf8"));
      })
      .filter((item): item is CaseMetadata => Boolean(item));
  }

  getCase(caseId: string): CaseMetadata | undefined {
    return this.listCases().find((item) => item.caseId === caseId);
  }

  searchCases(query: string, limit = 10): CaseMetadata[] {
    const normalizedQuery = query.trim().toLowerCase();
    if (!normalizedQuery) return [];

    return this.listCases()
      .map((item) => {
        const haystack = [
          item.caseId,
          item.title,
          item.chartType,
          item.chartTypeZh,
          item.aliases,
          item.bestFor,
          item.bestForZh,
          item.dataSchema,
          item.visualEncoding,
          item.ggplotComponents
        ]
          .join(" ")
          .toLowerCase();
        return { item, score: haystack.includes(normalizedQuery) ? 1 : 0 };
      })
      .filter((entry) => entry.score > 0)
      .slice(0, limit)
      .map((entry) => entry.item);
  }
}
```

- [ ] **Step 7: Run tests**

Run:

```bash
cd mcp/figureforge && npm test -- caseParser.test.ts caseStore.test.ts
```

Expected: PASS.

- [ ] **Step 8: Commit**

Run:

```bash
git add mcp/figureforge/src/caseParser.ts mcp/figureforge/src/caseStore.ts mcp/figureforge/tests
git commit -m "feat: parse and search FigureForge cases"
```

## Task 3: Add Read-Only MCP Tools

**Files:**
- Create: `mcp/figureforge/src/tools/health.ts`
- Create: `mcp/figureforge/src/tools/listCases.ts`
- Create: `mcp/figureforge/src/tools/searchCases.ts`
- Create: `mcp/figureforge/src/tools/getCase.ts`
- Modify: `mcp/figureforge/src/index.ts`
- Test: `mcp/figureforge/tests/readTools.test.ts`

- [ ] **Step 1: Write tool behavior tests**

Create `mcp/figureforge/tests/readTools.test.ts`:

```ts
import path from "node:path";
import { describe, expect, it } from "vitest";
import { runGetCase } from "../src/tools/getCase.js";
import { runHealth } from "../src/tools/health.js";
import { runListCases } from "../src/tools/listCases.js";
import { runSearchCases } from "../src/tools/searchCases.js";

const root = path.join(process.cwd(), "tests/fixtures");
const config = {
  root,
  skillPath: path.join(root, "skills/figureforge/SKILL.md"),
  casesDir: path.join(root, "cases"),
  scriptsDir: path.join(root, "scripts"),
  referencesDir: path.join(root, "references"),
  outputDir: path.join(root, "outputs/figureforge")
};

describe("read-only tools", () => {
  it("reports health", () => {
    const result = runHealth(config);
    expect(result.ok).toBe(true);
  });

  it("lists cases", () => {
    const result = runListCases(config, { limit: 5, offset: 0 });
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.data.cases[0].caseId).toBe("valid-bubble");
  });

  it("searches cases", () => {
    const result = runSearchCases(config, { query: "气泡图", limit: 5 });
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.data.cases[0].caseId).toBe("valid-bubble");
  });

  it("gets a case", () => {
    const result = runGetCase(config, { caseId: "valid-bubble" });
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.data.case.chartTypeZh).toBe("气泡图");
  });
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
cd mcp/figureforge && npm test -- readTools.test.ts
```

Expected: FAIL because tool files do not exist.

- [ ] **Step 3: Implement health tool**

Create `mcp/figureforge/src/tools/health.ts`:

```ts
import { existsSync } from "node:fs";
import type { FigureForgeConfig, ToolResult } from "../types.js";
import { CaseStore } from "../caseStore.js";

export function runHealth(config: FigureForgeConfig): ToolResult<{
  root: string;
  casesDir: string;
  scriptsDir: string;
  caseCount: number;
}> {
  if (!existsSync(config.root)) {
    return { ok: false, message: "FigureForge root does not exist.", detail: config.root };
  }

  const store = new CaseStore(config.casesDir);
  return {
    ok: true,
    data: {
      root: config.root,
      casesDir: config.casesDir,
      scriptsDir: config.scriptsDir,
      caseCount: store.listCases().length
    }
  };
}
```

- [ ] **Step 4: Implement list/search/get tools**

Create `mcp/figureforge/src/tools/listCases.ts`:

```ts
import { CaseStore } from "../caseStore.js";
import type { FigureForgeConfig, ToolResult } from "../types.js";

export function runListCases(
  config: FigureForgeConfig,
  input: { limit?: number; offset?: number }
): ToolResult<{ cases: ReturnType<CaseStore["listCases"]>; total: number }> {
  const limit = Math.max(1, Math.min(input.limit ?? 20, 100));
  const offset = Math.max(0, input.offset ?? 0);
  const cases = new CaseStore(config.casesDir).listCases();
  return { ok: true, data: { cases: cases.slice(offset, offset + limit), total: cases.length } };
}
```

Create `mcp/figureforge/src/tools/searchCases.ts`:

```ts
import { CaseStore } from "../caseStore.js";
import type { FigureForgeConfig, ToolResult } from "../types.js";

export function runSearchCases(
  config: FigureForgeConfig,
  input: { query: string; limit?: number }
): ToolResult<{ cases: ReturnType<CaseStore["searchCases"]> }> {
  const query = input.query.trim();
  if (!query) {
    return { ok: false, message: "Search query is required." };
  }

  const limit = Math.max(1, Math.min(input.limit ?? 10, 50));
  return { ok: true, data: { cases: new CaseStore(config.casesDir).searchCases(query, limit) } };
}
```

Create `mcp/figureforge/src/tools/getCase.ts`:

```ts
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { CaseStore } from "../caseStore.js";
import type { FigureForgeConfig, ToolResult } from "../types.js";

export function runGetCase(
  config: FigureForgeConfig,
  input: { caseId: string; includePlotScript?: boolean; includeDataPreview?: boolean }
): ToolResult<{ case: NonNullable<ReturnType<CaseStore["getCase"]>>; plotScript?: string; dataPreview?: string }> {
  const item = new CaseStore(config.casesDir).getCase(input.caseId);
  if (!item) {
    return { ok: false, message: "Unknown FigureForge case.", detail: input.caseId };
  }

  const result: { case: typeof item; plotScript?: string; dataPreview?: string } = { case: item };
  const plotPath = path.join(item.caseDir, "plot.R");
  const dataPath = path.join(item.caseDir, "data.csv");

  if (input.includePlotScript && existsSync(plotPath)) {
    result.plotScript = readFileSync(plotPath, "utf8");
  }
  if (input.includeDataPreview && existsSync(dataPath)) {
    result.dataPreview = readFileSync(dataPath, "utf8").split(/\r?\n/).slice(0, 6).join("\n");
  }

  return { ok: true, data: result };
}
```

- [ ] **Step 5: Register read-only tools in the MCP server**

Modify `mcp/figureforge/src/index.ts` to register:

```ts
import { z } from "zod";
import { runGetCase } from "./tools/getCase.js";
import { runHealth } from "./tools/health.js";
import { runListCases } from "./tools/listCases.js";
import { runSearchCases } from "./tools/searchCases.js";

function asText(data: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }] };
}

server.tool("figureforge_health", {}, async () => asText(runHealth(config)));

server.tool(
  "figureforge_list_cases",
  {
    limit: z.number().int().positive().max(100).optional(),
    offset: z.number().int().min(0).optional()
  },
  async (input) => asText(runListCases(config, input))
);

server.tool(
  "figureforge_search_cases",
  {
    query: z.string(),
    limit: z.number().int().positive().max(50).optional()
  },
  async (input) => asText(runSearchCases(config, input))
);

server.tool(
  "figureforge_get_case",
  {
    caseId: z.string(),
    includePlotScript: z.boolean().optional(),
    includeDataPreview: z.boolean().optional()
  },
  async (input) => asText(runGetCase(config, input))
);
```

Keep the server initialization and `server.connect` code from Task 1.

- [ ] **Step 6: Run tests and build**

Run:

```bash
cd mcp/figureforge && npm test && npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add mcp/figureforge/src mcp/figureforge/tests/readTools.test.ts
git commit -m "feat: add FigureForge MCP read tools"
```

## Task 4: Wrap Existing R Scripts

**Files:**
- Create: `mcp/figureforge/src/rScripts.ts`
- Create: `mcp/figureforge/src/tools/validateCase.ts`
- Create: `mcp/figureforge/src/tools/buildIndex.ts`
- Create: `mcp/figureforge/src/tools/renderCase.ts`
- Modify: `mcp/figureforge/src/index.ts`
- Test: `mcp/figureforge/tests/rScripts.test.ts`

- [ ] **Step 1: Write R wrapper tests**

Create `mcp/figureforge/tests/rScripts.test.ts`:

```ts
import path from "node:path";
import { describe, expect, it } from "vitest";
import { buildRscriptCommand } from "../src/rScripts.js";

describe("buildRscriptCommand", () => {
  it("builds a script command without shell interpolation", () => {
    const command = buildRscriptCommand("/repo/skills/figureforge/scripts/validate_case.R", [
      "/repo/skills/figureforge/cases/demo"
    ]);
    expect(command.command).toBe("Rscript");
    expect(command.args).toEqual([
      path.normalize("/repo/skills/figureforge/scripts/validate_case.R"),
      path.normalize("/repo/skills/figureforge/cases/demo")
    ]);
  });
});
```

- [ ] **Step 2: Run test and verify it fails**

Run:

```bash
cd mcp/figureforge && npm test -- rScripts.test.ts
```

Expected: FAIL because `rScripts.ts` does not exist.

- [ ] **Step 3: Implement R script helpers**

Create `mcp/figureforge/src/rScripts.ts`:

```ts
import { spawnSync } from "node:child_process";
import path from "node:path";

export function buildRscriptCommand(scriptPath: string, args: string[]) {
  return {
    command: "Rscript",
    args: [path.normalize(scriptPath), ...args.map((arg) => path.normalize(arg))]
  };
}

export function runRscript(scriptPath: string, args: string[]) {
  const command = buildRscriptCommand(scriptPath, args);
  const result = spawnSync(command.command, command.args, {
    encoding: "utf8",
    shell: false
  });

  return {
    status: result.status ?? 1,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
    error: result.error?.message
  };
}
```

- [ ] **Step 4: Implement validate/build/render tools**

Create `mcp/figureforge/src/tools/validateCase.ts`:

```ts
import path from "node:path";
import { CaseStore } from "../caseStore.js";
import { runRscript } from "../rScripts.js";
import type { FigureForgeConfig, ToolResult } from "../types.js";

export function runValidateCase(config: FigureForgeConfig, input: { caseId: string }): ToolResult<{ stdout: string; stderr: string }> {
  const item = new CaseStore(config.casesDir).getCase(input.caseId);
  if (!item) return { ok: false, message: "Unknown FigureForge case.", detail: input.caseId };

  const result = runRscript(path.join(config.scriptsDir, "validate_case.R"), [item.caseDir]);
  if (result.status !== 0) {
    return { ok: false, message: "Case validation failed.", detail: result.stderr || result.stdout || result.error };
  }
  return { ok: true, data: { stdout: result.stdout, stderr: result.stderr } };
}
```

Create `mcp/figureforge/src/tools/buildIndex.ts`:

```ts
import path from "node:path";
import { runRscript } from "../rScripts.js";
import type { FigureForgeConfig, ToolResult } from "../types.js";

export function runBuildIndex(config: FigureForgeConfig, input: { outputPath?: string } = {}): ToolResult<{ outputPath: string; stdout: string; stderr: string }> {
  const outputPath = input.outputPath ?? path.join(config.referencesDir, "case-index.csv");
  const result = runRscript(path.join(config.scriptsDir, "index_cases.R"), [config.casesDir, outputPath]);
  if (result.status !== 0) {
    return { ok: false, message: "Case index build failed.", detail: result.stderr || result.stdout || result.error };
  }
  return { ok: true, data: { outputPath, stdout: result.stdout, stderr: result.stderr } };
}
```

Create `mcp/figureforge/src/tools/renderCase.ts`:

```ts
import { mkdirSync } from "node:fs";
import path from "node:path";
import { CaseStore } from "../caseStore.js";
import { runRscript } from "../rScripts.js";
import type { FigureForgeConfig, ToolResult } from "../types.js";

export function runRenderCase(config: FigureForgeConfig, input: { caseId: string; outputPath?: string }): ToolResult<{ outputPath: string; stdout: string; stderr: string }> {
  const item = new CaseStore(config.casesDir).getCase(input.caseId);
  if (!item) return { ok: false, message: "Unknown FigureForge case.", detail: input.caseId };

  mkdirSync(config.outputDir, { recursive: true });
  const outputPath = input.outputPath ?? path.join(config.outputDir, `${input.caseId}.png`);
  const result = runRscript(path.join(config.scriptsDir, "render_case.R"), [item.caseDir, outputPath]);

  if (result.status !== 0) {
    return { ok: false, message: "Case rendering failed.", detail: result.stderr || result.stdout || result.error };
  }
  return { ok: true, data: { outputPath, stdout: result.stdout, stderr: result.stderr } };
}
```

- [ ] **Step 5: Register R-backed tools**

Modify `mcp/figureforge/src/index.ts` to register:

```ts
import { runBuildIndex } from "./tools/buildIndex.js";
import { runRenderCase } from "./tools/renderCase.js";
import { runValidateCase } from "./tools/validateCase.js";

server.tool("figureforge_build_index", { outputPath: z.string().optional() }, async (input) =>
  asText(runBuildIndex(config, input))
);

server.tool("figureforge_validate_case", { caseId: z.string() }, async (input) =>
  asText(runValidateCase(config, input))
);

server.tool(
  "figureforge_render_case",
  { caseId: z.string(), outputPath: z.string().optional() },
  async (input) => asText(runRenderCase(config, input))
);
```

- [ ] **Step 6: Run tests and build**

Run:

```bash
cd mcp/figureforge && npm test && npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add mcp/figureforge/src mcp/figureforge/tests/rScripts.test.ts
git commit -m "feat: wrap FigureForge R helper scripts"
```

## Task 5: Add Mapping Suggestions

**Files:**
- Create: `mcp/figureforge/src/tools/suggestMapping.ts`
- Modify: `mcp/figureforge/src/index.ts`
- Test: `mcp/figureforge/tests/suggestMapping.test.ts`

- [ ] **Step 1: Write mapping tests**

Create `mcp/figureforge/tests/suggestMapping.test.ts`:

```ts
import path from "node:path";
import { describe, expect, it } from "vitest";
import { runSuggestMapping } from "../src/tools/suggestMapping.js";

const root = path.join(process.cwd(), "tests/fixtures");
const config = {
  root,
  skillPath: path.join(root, "skills/figureforge/SKILL.md"),
  casesDir: path.join(root, "cases"),
  scriptsDir: path.join(root, "scripts"),
  referencesDir: path.join(root, "references"),
  outputDir: path.join(root, "outputs/figureforge")
};

describe("runSuggestMapping", () => {
  it("maps matching user columns to case roles", () => {
    const result = runSuggestMapping(config, {
      caseId: "valid-bubble",
      columns: ["term", "group", "score", "count", "extra"]
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.mapping.find((row) => row.caseRole === "term")?.userColumn).toBe("term");
      expect(result.data.missingRequiredRoles).toEqual([]);
    }
  });
});
```

- [ ] **Step 2: Run test and verify it fails**

Run:

```bash
cd mcp/figureforge && npm test -- suggestMapping.test.ts
```

Expected: FAIL because `suggestMapping.ts` does not exist.

- [ ] **Step 3: Implement deterministic mapping**

Create `mcp/figureforge/src/tools/suggestMapping.ts`:

```ts
import { CaseStore } from "../caseStore.js";
import type { FigureForgeConfig, ToolResult } from "../types.js";

type MappingRow = {
  caseRole: string;
  userColumn: string | null;
  confidence: "exact" | "missing";
};

function extractRoles(dataSchema: string): string[] {
  const match = dataSchema.match(/columns:\s*([^.`]+)/i);
  if (!match) return [];
  return match[1]
    .split(",")
    .map((item) => item.trim().replace(/[.。]$/, ""))
    .filter(Boolean);
}

export function runSuggestMapping(
  config: FigureForgeConfig,
  input: { caseId: string; columns: string[] }
): ToolResult<{ mapping: MappingRow[]; missingRequiredRoles: string[] }> {
  const item = new CaseStore(config.casesDir).getCase(input.caseId);
  if (!item) return { ok: false, message: "Unknown FigureForge case.", detail: input.caseId };

  const normalizedColumns = new Map(input.columns.map((column) => [column.toLowerCase(), column]));
  const roles = extractRoles(item.dataSchema);
  const mapping = roles.map((role) => {
    const userColumn = normalizedColumns.get(role.toLowerCase()) ?? null;
    return {
      caseRole: role,
      userColumn,
      confidence: userColumn ? "exact" : "missing"
    } satisfies MappingRow;
  });

  return {
    ok: true,
    data: {
      mapping,
      missingRequiredRoles: mapping.filter((row) => !row.userColumn).map((row) => row.caseRole)
    }
  };
}
```

- [ ] **Step 4: Register mapping tool**

Modify `mcp/figureforge/src/index.ts`:

```ts
import { runSuggestMapping } from "./tools/suggestMapping.js";

server.tool(
  "figureforge_suggest_mapping",
  { caseId: z.string(), columns: z.array(z.string()) },
  async (input) => asText(runSuggestMapping(config, input))
);
```

- [ ] **Step 5: Run tests and build**

Run:

```bash
cd mcp/figureforge && npm test && npm run build
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add mcp/figureforge/src mcp/figureforge/tests/suggestMapping.test.ts
git commit -m "feat: add FigureForge mapping suggestions"
```

## Task 6: Connect the Skill Layer to MCP

**Files:**
- Modify: `skills/figureforge/SKILL.md`
- Modify: `README.md`
- Modify: `README.zh.md`
- Create: `mcp/figureforge/README.md`

- [ ] **Step 1: Update `SKILL.md` with MCP guidance**

Add this section after `## Core Rule`:

```markdown
## MCP Tool Layer

When the FigureForge MCP server is available, prefer it for case discovery and repeatable operations:

- Use `figureforge_health` before relying on local cases.
- Use `figureforge_search_cases` or `figureforge_list_cases` before manually scanning `cases/`.
- Use `figureforge_get_case` to inspect structured metadata.
- Use `figureforge_validate_case` and `figureforge_render_case` for repeatable checks.
- Use `figureforge_suggest_mapping` as a first draft only; the agent must still explain and verify the final column mapping.

If MCP is unavailable, fall back to reading `references/`, `case.md`, `plot.R`, and data files directly, then run the R helper scripts from the repository root.
```

- [ ] **Step 2: Create MCP README**

Create `mcp/figureforge/README.md`:

```markdown
# FigureForge MCP Server

This package exposes FigureForge as a local MCP server for AI agents.

The skill layer explains how agents should reason about case-based figure adaptation. The MCP layer provides callable tools for case discovery, metadata inspection, validation, indexing, rendering, and mapping suggestions.

## Tools

- `figureforge_health`
- `figureforge_list_cases`
- `figureforge_search_cases`
- `figureforge_get_case`
- `figureforge_build_index`
- `figureforge_validate_case`
- `figureforge_render_case`
- `figureforge_suggest_mapping`

## Local Development

```bash
cd mcp/figureforge
npm install
npm test
npm run build
FIGUREFORGE_ROOT=/absolute/path/to/FigureForge npm run dev
```

## Private Corpus Boundary

The MCP server can read a local private FigureForge case corpus. That does not mean the corpus is redistributable. Public packages should include only cleaned cases whose data, scripts, and images can be shared.
```

- [ ] **Step 3: Update root READMEs**

In `README.md`, add a section:

```markdown
## Skill + MCP Product Direction

FigureForge is designed as a dual-layer agent product:

- The skill layer teaches agents how to select, map, adapt, render, and QA scientific figure cases.
- The MCP layer exposes stable tools for other agents to list cases, search metadata, inspect schemas, validate cases, rebuild indexes, render outputs, and draft column mappings.

The full local case corpus may contain private or third-party assets. Public releases should include only redistributable cases.
```

In `README.zh.md`, add:

```markdown
## Skill + MCP 产品方向

FigureForge 将按双层 Agent 产品发展:

- Skill 层负责告诉 Agent 如何选案例、做列映射、迁移绘图代码、渲染与质检。
- MCP 层负责把案例检索、元数据读取、结构校验、索引重建、图形渲染和列映射建议变成其他 Agent 可调用的稳定工具。

完整本地案例库可能包含私有或第三方素材。公开发布时只应包含可再分发的清理版案例。
```

- [ ] **Step 4: Run documentation checks**

Run:

```bash
test -f mcp/figureforge/README.md
rg -n "figureforge_health|Skill \\+ MCP|MCP Tool Layer" README.md README.zh.md skills/figureforge/SKILL.md mcp/figureforge/README.md
```

Expected: commands find the new MCP guidance.

- [ ] **Step 5: Commit**

Run:

```bash
git add README.md README.zh.md skills/figureforge/SKILL.md mcp/figureforge/README.md
git commit -m "docs: document FigureForge Skill and MCP layers"
```

## Task 7: Final Verification

**Files:**
- No new files.

- [ ] **Step 1: Run full MCP verification**

Run:

```bash
cd mcp/figureforge && npm test && npm run build
```

Expected: PASS.

- [ ] **Step 2: Verify existing R helpers still work on local cases**

Run:

```bash
Rscript skills/figureforge/scripts/index_cases.R mcp/figureforge/tests/fixtures/cases /tmp/figureforge-fixture-index.csv
Rscript skills/figureforge/scripts/validate_case.R mcp/figureforge/tests/fixtures/cases/valid-bubble
```

Expected:

- First command writes `/tmp/figureforge-fixture-index.csv` with one fixture row.
- Second command prints `Case structure OK: mcp/figureforge/tests/fixtures/cases/valid-bubble`.

- [ ] **Step 3: Verify public/private boundary**

Run:

```bash
git status --short --untracked-files=all
git check-ignore -v skills/figureforge/cases/* | sed -n '1,20p'
```

Expected:

- MCP source, tests, and docs are tracked or ready to track.
- Private case corpus remains ignored unless specific cleaned cases are intentionally unignored later.

- [ ] **Step 4: Final commit if needed**

Run:

```bash
git status --short
```

If verification changes documentation or generated files intentionally, commit them with:

```bash
git add <changed-files>
git commit -m "chore: verify FigureForge MCP development baseline"
```

## Execution Recommendation

Use subagent-driven development for implementation:

1. One subagent implements package scaffold.
2. One subagent implements parser/store.
3. One subagent implements MCP read-only tools.
4. One subagent implements R wrappers.
5. One subagent implements mapping suggestions and docs.
6. Main agent reviews each step and runs verification.

The first release should stop at a local MCP server. Do not publish an npm package or public case corpus until the public/private asset boundary has been reviewed.

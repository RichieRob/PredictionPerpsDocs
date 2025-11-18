#!/usr/bin/env python3
import os
import sys
import urllib.parse
import re

try:
    import yaml
    from yaml.loader import SafeLoader
except ImportError:
    print("This script requires PyYAML. Install with: pip install pyyaml")
    sys.exit(1)

MKDOCS_YML = "mkdocs.yml"
OUTPUT_MD = "slugs.md"
LINK_REFS_MD = os.path.join("docs", "link-refs.md")
INCLUDE_LINE = '--8<-- "link-refs.md"'


# Static mapping: contract filename or collection → GitHub URL
CONTRACT_REFS = {
    # === Root repo ===
    "contracts-root": "https://github.com/RichieRob/PredictionPerpsContracts/tree/main",

    # === Folders ===
    "amm-libraries": "https://github.com/RichieRob/PredictionPerpsContracts/tree/main/Core/AMMLibraries",
    "ledger-libraries": "https://github.com/RichieRob/PredictionPerpsContracts/tree/main/Core/LedgerLibraries",
    "interfaces": "https://github.com/RichieRob/PredictionPerpsContracts/tree/main/Interfaces",

    # === Core Contracts ===
    "LMSRMarketMaker.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LMSRMarketMaker.sol",
    "Ledger.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/Ledger.sol",
    "PositionToken1155.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/PositionToken1155.sol",

    # === Interfaces ===
    "IERC20Permit.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/IERC20Permit.sol",
    "ILedger.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/ILedger.sol",
    "IPermit2.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/IPermit2.sol",
    "iPositionToken1155.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Interfaces/iPositionToken1155.sol",

    # === Ledger Libraries ===
    "AllocateCapitalLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/AllocateCapitalLib.sol",
    "DepositWithdrawLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/DepositWithdrawLib.sol",
    "HeapLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/HeapLib.sol",
    "LedgerLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/LedgerLib.sol",
    "LiquidityLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/LiquidityLib.sol",
    "MarketManagementLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/MarketManagementLib.sol",
    "RedemptionLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/RedemptionLib.sol",
    "SolvencyLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/SolvencyLib.sol",
    "StorageLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/StorageLib.sol",
    "TokenOpsLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/TokenOpsLib.sol",
    "TradingLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/TradingLib.sol",
    "Types.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/Types.sol",
    "TypesPermit.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/LedgerLibraries/TypesPermit.sol",

    # === AMM Libraries ===
    "LMSRExecutionLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRExecutionLib.sol",
    "LMSRExpansionLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRExpansionLib.sol",
    "LMSRHelpersLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRHelpersLib.sol",
    "LMSRInitLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRInitLib.sol",
    "LMSRMathLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRMathLib.sol",
    "LMSRQuoteLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRQuoteLib.sol",
    "LMSRUpdateLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRUpdateLib.sol",
    "LMSRViewLib.sol": "https://github.com/RichieRob/PredictionPerpsContracts/blob/main/Core/AMMLibraries/LMSRViewLib.sol",
}


class MkdocsLoader(SafeLoader):
    pass


def mermaid2_constructor(loader, node):
    return loader.construct_scalar(node)


MkdocsLoader.add_constructor(
    "tag:yaml.org,2002:python/name:mermaid2.fence_mermaid",
    mermaid2_constructor,
)


def load_mkdocs_config(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.load(f, Loader=MkdocsLoader)


def extract_paths_from_nav(nav_section):
    paths = []
    if not isinstance(nav_section, list):
        return paths

    for item in nav_section:
        if isinstance(item, dict):
            for _label, value in item.items():
                if isinstance(value, str) and value.endswith(".md"):
                    paths.append(value)
                elif isinstance(value, list):
                    paths.extend(extract_paths_from_nav(value))
        elif isinstance(item, str) and item.endswith(".md"):
            paths.append(item)

    return paths


def parse_front_matter(md_path: str):
    """
    Returns (title, slug) from YAML front matter, or (None, None) if absent.
    """
    if not os.path.isfile(md_path):
        return None, None

    with open(md_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if not lines or not lines[0].strip().startswith("---"):
        return None, None

    end_index = None
    for i in range(1, len(lines)):
        if lines[i].strip().startswith("---"):
            end_index = i
            break

    if end_index is None:
        return None, None

    front_matter_str = "".join(lines[1:end_index])
    try:
        data = yaml.safe_load(front_matter_str) or {}
    except Exception:
        return None, None

    return data.get("title"), data.get("slug")


def slugify_heading(text: str) -> str:
    """
    Roughly match MkDocs/Markdown heading → ID generation:
    - lower-case
    - replace spaces with '-'
    - remove invalid chars
    - collapse multiple '-'
    """
    text = text.strip().lower()
    # Replace spaces with dash
    text = re.sub(r"\s+", "-", text)
    # Remove anything not alphanumeric, dash or underscore
    text = re.sub(r"[^a-z0-9\-_]", "", text)
    # Collapse multiple dashes
    text = re.sub(r"-{2,}", "-", text)
    # Strip leading/trailing dashes
    text = text.strip("-")
    return text


def extract_anchors(md_path: str) -> list:
    """
    Extract heading-based anchors from a markdown file (ignoring front matter).
    Returns a list of anchor IDs like ["position", "liquidity", ...].
    """
    if not os.path.isfile(md_path):
        return []

    with open(md_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    anchors = []

    # Skip front matter if present
    start_idx = 0
    if lines and lines[0].strip().startswith("---"):
        for i in range(1, len(lines)):
            if lines[i].strip().startswith("---"):
                start_idx = i + 1
                break

    for line in lines[start_idx:]:
        stripped = line.lstrip()
        if not stripped.startswith("#"):
            continue

        # Heading line like "## Position" or "# Glossary"
        # Remove leading hashes and whitespace
        heading_text = stripped.lstrip("#").strip()
        if not heading_text:
            continue

        anchor = slugify_heading(heading_text)
        if anchor:
            anchors.append(anchor)

    return anchors


def ensure_link_include(full_path):
    """
    Append the snippets include line if not already present.
    """
    with open(full_path, "r+", encoding="utf-8") as f:
        content = f.read()

        if INCLUDE_LINE in content:
            return False

        new_content = content.rstrip() + "\n\n" + INCLUDE_LINE + "\n"
        f.seek(0)
        f.write(new_content)
        f.truncate()
        return True


def main():
    if not os.path.isfile(MKDOCS_YML):
        print(f"Could not find {MKDOCS_YML} in current directory.")
        sys.exit(1)

    config = load_mkdocs_config(MKDOCS_YML)
    docs_dir = config.get("docs_dir", "docs")
    nav = config.get("nav", [])

    md_paths = extract_paths_from_nav(nav)
    seen = set()
    ordered_paths = []
    for p in md_paths:
        if p not in seen:
            seen.add(p)
            ordered_paths.append(p)

    rows = []
    for rel_path in ordered_paths:
        full_path = os.path.join(docs_dir, rel_path)
        title, slug = parse_front_matter(full_path)
        rows.append({
            "path": rel_path,
            "title": title or "",
            "slug": slug or "",
            "full_path": full_path,
        })

    # slugs.md (overview)
    with open(OUTPUT_MD, "w", encoding="utf-8") as out:
        out.write("# Slugs\n\n")
        out.write("| Path | Title | Slug |\n")
        out.write("| --- | --- | --- |\n")
        for row in rows:
            out.write(f"| `{row['path']}` | {row['title']} | `{row['slug']}` |\n")

    # Build base slug refs and anchor refs
    os.makedirs(docs_dir, exist_ok=True)

    slug_refs = {}     # slug → URL
    anchor_refs = {}   # "slug#anchor" → URL#anchor

    for row in rows:
        slug = (row["slug"] or "").strip()
        rel_path = row["path"].strip()
        if not slug:
            continue

        # Strip .md
        rel_no_ext = rel_path[:-3] if rel_path.lower().endswith(".md") else rel_path
        # URL-encode path (spaces, etc.), keep "/"
        encoded = urllib.parse.quote(rel_no_ext, safe="/")

        if encoded == "index":
            base_url = "/"
        else:
            base_url = "/" + encoded

        # Base slug ref
        slug_refs[slug] = base_url

        # Anchor refs: scan headings in this file
        full_path = row["full_path"]
        anchors = extract_anchors(full_path)
        for anchor in anchors:
            label = f"{slug}#{anchor}"
            # e.g. /Technical/5%20Appendices/Glossary#position
            anchor_refs[label] = f"{base_url}#{anchor}"

    # Write docs/link-refs.md
    with open(LINK_REFS_MD, "w", encoding="utf-8") as f:
        # 1) Slug-based internal pages
        for slug in sorted(slug_refs.keys()):
            f.write(f"[{slug}]: {slug_refs[slug]}\n")

        f.write("\n")

        # 2) Anchored refs like glossary#position
        for label in sorted(anchor_refs.keys()):
            f.write(f"[{label}]: {anchor_refs[label]}\n")

        f.write("\n")

        # 3) Contract / folder refs (GitHub)
        for name, url in sorted(CONTRACT_REFS.items()):
            f.write(f"[{name}]: {url}\n")

    # Inject include line into each .md once
    changed = 0
    for row in rows:
        if ensure_link_include(row["full_path"]):
            changed += 1

    print(f"Wrote {len(rows)} entries to {OUTPUT_MD}")
    print(f"Wrote {len(slug_refs)} slug refs, {len(anchor_refs)} anchor refs "
          f"and {len(CONTRACT_REFS)} contract refs to {LINK_REFS_MD}")
    print(f"Injected include line into {changed} files")


if __name__ == "__main__":
    main()

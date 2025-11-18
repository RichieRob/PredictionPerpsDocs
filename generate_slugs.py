#!/usr/bin/env python3
import os
import sys
import urllib.parse

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

# Static mapping: contract filename -> GitHub URL
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


def ensure_link_include(full_path):
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

    # slugs.md (for overview)
    with open(OUTPUT_MD, "w", encoding="utf-8") as out:
        out.write("# Slugs\n\n")
        out.write("| Path | Title | Slug |\n")
        out.write("| --- | --- | --- |\n")
        for row in rows:
            out.write(f"| `{row['path']}` | {row['title']} | `{row['slug']}` |\n")

    # link-refs.md (used everywhere via snippets)
    os.makedirs(docs_dir, exist_ok=True)
    link_lines = []
    seen_slugs = set()

    for row in rows:
        slug = row["slug"].strip()
        rel_path = row["path"].strip()
        if not slug or slug in seen_slugs:
            continue
        seen_slugs.add(slug)

        # Strip .md
        rel_no_ext = rel_path[:-3] if rel_path.lower().endswith(".md") else rel_path
        # URL-encode (spaces etc), keep "/"
        encoded = urllib.parse.quote(rel_no_ext, safe="/")

        if encoded == "index":
            link_target = "/"
        else:
            link_target = "/" + encoded

        link_lines.append(f"[{slug}]: {link_target}")

    with open(LINK_REFS_MD, "w", encoding="utf-8") as f:
        # First: slug-based internal links
        for line in sorted(link_lines):
            f.write(line + "\n")
        f.write("\n")
        # Then: contract GitHub links
        for name, url in sorted(CONTRACT_REFS.items()):
            f.write(f"[{name}]: {url}\n")

    # Inject include line into each .md once
    changed = 0
    for row in rows:
        if ensure_link_include(row["full_path"]):
            changed += 1

    print(f"Wrote {len(rows)} entries to {OUTPUT_MD}")
    print(f"Wrote {len(link_lines)} slug refs and {len(CONTRACT_REFS)} contract refs to {LINK_REFS_MD}")
    print(f"Injected include line into {changed} files")


if __name__ == "__main__":
    main()

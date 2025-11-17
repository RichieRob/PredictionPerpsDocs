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

    # slugs.md (debug/overview)
    with open(OUTPUT_MD, "w", encoding="utf-8") as out:
        out.write("# Slugs\n\n")
        out.write("| Path | Title | Slug |\n")
        out.write("| --- | --- | --- |\n")
        for row in rows:
            out.write(f"| `{row['path']}` | {row['title']} | `{row['slug']}` |\n")

    # link-refs.md (reference definitions only)
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

        # URL-encode (spaces → %20, etc.), but keep slashes
        encoded = urllib.parse.quote(rel_no_ext, safe="/")

        # Special-case root index
        if encoded == "index":
            link_target = "/"
        else:
            link_target = "/" + encoded

        link_lines.append(f"[{slug}]: {link_target}")

    with open(LINK_REFS_MD, "w", encoding="utf-8") as f:
        for line in sorted(link_lines):
            f.write(line + "\n")

    # Inject include into each .md
    changed = 0
    for row in rows:
        if ensure_link_include(row["full_path"]):
            changed += 1

    print(f"Wrote {len(rows)} entries to {OUTPUT_MD}")
    print(f"Wrote {len(link_lines)} link refs to {LINK_REFS_MD}")
    print(f"Injected include line into {changed} files")


if __name__ == "__main__":
    main()

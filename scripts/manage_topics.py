#!/usr/bin/env python3
"""
BiGuess Game - Topic & Pack Management CLI & Interactive Tool
Easily Create, Read, Update, and Delete Topics and Packs in assets/images/
with automated synchronization of lib/assets_manifest.dart and pubspec.yaml.
"""

import argparse
import os
import shutil
import sys
from pathlib import Path
from typing import Dict, List, Optional

# Add scripts directory to path to reuse generate_manifest
SCRIPTS_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPTS_DIR.parent
sys.path.insert(0, str(SCRIPTS_DIR))

from generate_manifest import (  # noqa: E402
    scan_topic_pack_assets,
    generate_dart_content,
    sync_pubspec_assets,
    VALID_EXTENSIONS,
)

# ANSI colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

IMAGES_DIR = REPO_ROOT / "assets" / "images"
MANIFEST_FILE = REPO_ROOT / "lib" / "assets_manifest.dart"
PUBSPEC_FILE = REPO_ROOT / "pubspec.yaml"


def sync_all() -> None:
    """Synchronize both lib/assets_manifest.dart and pubspec.yaml."""
    manifest = scan_topic_pack_assets(IMAGES_DIR)
    dart_code = generate_dart_content(manifest)
    MANIFEST_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(MANIFEST_FILE, "w", encoding="utf-8") as f:
        f.write(dart_code)
    sync_pubspec_assets(PUBSPEC_FILE, manifest)


def list_topics_and_packs() -> None:
    """Print a clean visual breakdown of all topics, packs, and items."""
    manifest = scan_topic_pack_assets(IMAGES_DIR)
    print(f"\n{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}")
    print(f"{BOLD}{CYAN}             📂  BiGuess Topics & Packs Inventory              {RESET}")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")

    if not manifest:
        print(f"{YELLOW}⚠️  No topics or packs found in assets/images/{RESET}\n")
        return

    total_topics = len(manifest)
    total_packs = 0
    total_items = 0

    for topic, packs in sorted(manifest.items()):
        pack_count = len(packs)
        topic_items = sum(len(items) for items in packs.values())
        total_packs += pack_count
        total_items += topic_items

        print(f"  {MAGENTA}📁 Topic: {BOLD}{topic}{RESET} {DIM}({pack_count} packs, {topic_items} items){RESET}")
        for pack, items in sorted(packs.items()):
            count = len(items)
            badge = f"{GREEN}{count:>4} items{RESET}" if count > 0 else f"{RED}empty{RESET}"
            print(f"     ├── 📦 {pack:<25} {badge}")
        print()

    print(f"{CYAN}──────────────────────────────────────────────────────────────{RESET}")
    print(f"  {BOLD}Summary:{RESET} {total_topics} topics | {total_packs} packs | {total_items} items total")
    print(f"{BOLD}{CYAN}══════════════════════════════════════════════════════════════{RESET}\n")


def create_topic(topic_name: str) -> bool:
    """Create a new topic directory."""
    topic_clean = topic_name.strip()
    if not topic_clean:
        print(f"{RED}❌ Topic name cannot be empty.{RESET}")
        return False

    target_dir = IMAGES_DIR / topic_clean
    if target_dir.exists():
        print(f"{YELLOW}⚠️  Topic '{topic_clean}' already exists at {target_dir}{RESET}")
        return False

    target_dir.mkdir(parents=True, exist_ok=True)
    print(f"{GREEN}✅ Created topic '{topic_clean}' at: {target_dir}{RESET}")
    return True


def create_pack(topic_name: str, pack_name: str) -> bool:
    """Create a new pack inside a topic."""
    topic_clean = topic_name.strip()
    pack_clean = pack_name.strip()

    if not topic_clean or not pack_clean:
        print(f"{RED}❌ Topic and Pack names cannot be empty.{RESET}")
        return False

    topic_dir = IMAGES_DIR / topic_clean
    if not topic_dir.exists():
        topic_dir.mkdir(parents=True, exist_ok=True)
        print(f"{CYAN}ℹ️  Created parent topic '{topic_clean}'.{RESET}")

    pack_dir = topic_dir / pack_clean
    if pack_dir.exists():
        print(f"{YELLOW}⚠️  Pack '{pack_clean}' already exists in topic '{topic_clean}'.{RESET}")
        return False

    pack_dir.mkdir(parents=True, exist_ok=True)
    print(f"{GREEN}✅ Created pack '{pack_clean}' in topic '{topic_clean}'.{RESET}")
    sync_all()
    return True


def rename_topic(old_name: str, new_name: str) -> bool:
    """Rename an existing topic."""
    old_clean = old_name.strip()
    new_clean = new_name.strip()

    old_dir = IMAGES_DIR / old_clean
    new_dir = IMAGES_DIR / new_clean

    if not old_dir.exists():
        print(f"{RED}❌ Topic '{old_clean}' does not exist.{RESET}")
        return False

    if new_dir.exists():
        print(f"{RED}❌ Target topic '{new_clean}' already exists.{RESET}")
        return False

    old_dir.rename(new_dir)
    print(f"{GREEN}✅ Renamed topic '{old_clean}' ➔ '{new_clean}'.{RESET}")
    sync_all()
    return True


def rename_pack(topic_name: str, old_pack: str, new_pack: str) -> bool:
    """Rename an existing pack inside a topic."""
    topic_clean = topic_name.strip()
    old_clean = old_pack.strip()
    new_clean = new_pack.strip()

    topic_dir = IMAGES_DIR / topic_clean
    if not topic_dir.exists():
        print(f"{RED}❌ Topic '{topic_clean}' does not exist.{RESET}")
        return False

    old_dir = topic_dir / old_clean
    new_dir = topic_dir / new_clean

    if not old_dir.exists():
        print(f"{RED}❌ Pack '{old_clean}' does not exist in topic '{topic_clean}'.{RESET}")
        return False

    if new_dir.exists():
        print(f"{RED}❌ Target pack '{new_clean}' already exists in topic '{topic_clean}'.{RESET}")
        return False

    old_dir.rename(new_dir)
    print(f"{GREEN}✅ Renamed pack '{old_clean}' ➔ '{new_clean}' in topic '{topic_clean}'.{RESET}")
    sync_all()
    return True


def delete_pack(topic_name: str, pack_name: str, force: bool = False) -> bool:
    """Delete a pack directory and its contents."""
    topic_clean = topic_name.strip()
    pack_clean = pack_name.strip()

    pack_dir = IMAGES_DIR / topic_clean / pack_clean
    if not pack_dir.exists():
        print(f"{RED}❌ Pack '{pack_clean}' does not exist in topic '{topic_clean}'.{RESET}")
        return False

    item_count = sum(1 for item in pack_dir.iterdir() if item.is_file() and not item.name.startswith("."))
    if item_count > 0 and not force:
        print(f"{YELLOW}⚠️  Pack '{pack_clean}' contains {item_count} items!{RESET}")
        confirm = input(f"Are you sure you want to permanently delete this pack? (type 'yes' to confirm): ").strip().lower()
        if confirm != "yes":
            print(f"{YELLOW}Operation cancelled.{RESET}")
            return False

    shutil.rmtree(pack_dir)
    print(f"{GREEN}✅ Deleted pack '{pack_clean}' from topic '{topic_clean}'.{RESET}")
    sync_all()
    return True


def delete_topic(topic_name: str, force: bool = False) -> bool:
    """Delete a topic directory and all its packs."""
    topic_clean = topic_name.strip()
    topic_dir = IMAGES_DIR / topic_clean

    if not topic_dir.exists():
        print(f"{RED}❌ Topic '{topic_clean}' does not exist.{RESET}")
        return False

    # Check if contains items
    total_items = sum(
        1 for p in topic_dir.rglob("*") if p.is_file() and not p.name.startswith(".")
    )

    if total_items > 0 and not force:
        print(f"{RED}⚠️  Topic '{topic_clean}' contains {total_items} items across its packs!{RESET}")
        confirm = input(f"Are you sure you want to permanently delete topic '{topic_clean}'? (type 'yes' to confirm): ").strip().lower()
        if confirm != "yes":
            print(f"{YELLOW}Operation cancelled.{RESET}")
            return False

    shutil.rmtree(topic_dir)
    print(f"{GREEN}✅ Deleted topic '{topic_clean}' and all contents.{RESET}")
    sync_all()
    return True


# =============================================================================
# Interactive Menu
# =============================================================================

def interactive_menu() -> None:
    """Launch an interactive CRUD console interface for Topics and Packs."""
    while True:
        print(f"\n{BOLD}{CYAN}╔══════════════════════════════════════════════════════════════╗{RESET}")
        print(f"{BOLD}{CYAN}║             📂  TOPIC & PACK MANAGER (CRUD)                  ║{RESET}")
        print(f"{BOLD}{CYAN}╚══════════════════════════════════════════════════════════════╝{RESET}")
        print(f"  {CYAN}[1]{RESET} 📋 List all Topics & Packs")
        print(f"  {CYAN}[2]{RESET} ➕ Create New Topic")
        print(f"  {CYAN}[3]{RESET} 📦 Create New Pack inside Topic")
        print(f"  {CYAN}[4]{RESET} ✏️  Rename Topic")
        print(f"  {CYAN}[5]{RESET} ✏️  Rename Pack")
        print(f"  {CYAN}[6]{RESET} 🗑️  Delete Pack")
        print(f"  {CYAN}[7]{RESET} 🗑️  Delete Topic")
        print(f"  {CYAN}[8]{RESET} 🔄 Sync Manifest & pubspec.yaml")
        print(f"  {CYAN}[0]{RESET} ↩️  Exit\n")

        try:
            choice = input(f"{BOLD}Select an option [0-8]: {RESET}").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nExiting...")
            break

        if choice == "0" or choice.lower() in ("q", "exit", "quit"):
            break
        elif choice == "1":
            list_topics_and_packs()
        elif choice == "2":
            name = input("Enter new Topic name: ").strip()
            if name:
                create_topic(name)
        elif choice == "3":
            manifest = scan_topic_pack_assets(IMAGES_DIR)
            topics = sorted(manifest.keys())
            if topics:
                print(f"Existing topics: {', '.join(topics)}")
            topic = input("Enter Topic name: ").strip()
            pack = input("Enter new Pack name: ").strip()
            if topic and pack:
                create_pack(topic, pack)
        elif choice == "4":
            old_name = input("Enter current Topic name: ").strip()
            new_name = input("Enter new Topic name: ").strip()
            if old_name and new_name:
                rename_topic(old_name, new_name)
        elif choice == "5":
            topic = input("Enter Topic name: ").strip()
            old_pack = input("Enter current Pack name: ").strip()
            new_pack = input("Enter new Pack name: ").strip()
            if topic and old_pack and new_pack:
                rename_pack(topic, old_pack, new_pack)
        elif choice == "6":
            topic = input("Enter Topic name: ").strip()
            pack = input("Enter Pack name to delete: ").strip()
            if topic and pack:
                delete_pack(topic, pack)
        elif choice == "7":
            topic = input("Enter Topic name to delete: ").strip()
            if topic:
                delete_topic(topic)
        elif choice == "8":
            sync_all()
            print(f"{GREEN}✅ Assets manifest and pubspec.yaml synchronized!{RESET}")
        else:
            print(f"{RED}Invalid option. Please choose between 0 and 8.{RESET}")


# =============================================================================
# CLI Entrypoint
# =============================================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        description="CRUD utility for BiGuess Topics and Packs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # list
    subparsers.add_parser("list", help="List all topics, packs, and item counts")

    # create-topic
    p_ct = subparsers.add_parser("create-topic", help="Create a new topic folder")
    p_ct.add_argument("name", help="Name of the topic")

    # create-pack
    p_cp = subparsers.add_parser("create-pack", help="Create a new pack inside a topic")
    p_cp.add_argument("topic", help="Name of the parent topic")
    p_cp.add_argument("name", help="Name of the pack")

    # rename-topic
    p_rt = subparsers.add_parser("rename-topic", help="Rename an existing topic")
    p_rt.add_argument("old_name", help="Current topic name")
    p_rt.add_argument("new_name", help="New topic name")

    # rename-pack
    p_rp = subparsers.add_parser("rename-pack", help="Rename a pack inside a topic")
    p_rp.add_argument("topic", help="Parent topic name")
    p_rp.add_argument("old_name", help="Current pack name")
    p_rp.add_argument("new_name", help="New pack name")

    # delete-pack
    p_dp = subparsers.add_parser("delete-pack", help="Delete a pack inside a topic")
    p_dp.add_argument("topic", help="Parent topic name")
    p_dp.add_argument("name", help="Pack name")
    p_dp.add_argument("-f", "--force", action="store_true", help="Bypass confirmation prompt")

    # delete-topic
    p_dt = subparsers.add_parser("delete-topic", help="Delete a topic and all its packs")
    p_dt.add_argument("name", help="Topic name")
    p_dt.add_argument("-f", "--force", action="store_true", help="Bypass confirmation prompt")

    # sync
    subparsers.add_parser("sync", help="Sync assets_manifest.dart and pubspec.yaml")

    args = parser.parse_args()

    if not args.command:
        # If no arguments passed, launch interactive menu
        interactive_menu()
        return 0

    if args.command == "list":
        list_topics_and_packs()
    elif args.command == "create-topic":
        create_topic(args.name)
    elif args.command == "create-pack":
        create_pack(args.topic, args.name)
    elif args.command == "rename-topic":
        rename_topic(args.old_name, args.new_name)
    elif args.command == "rename-pack":
        rename_pack(args.topic, args.old_name, args.new_name)
    elif args.command == "delete-pack":
        delete_pack(args.topic, args.name, force=args.force)
    elif args.command == "delete-topic":
        delete_topic(args.name, force=args.force)
    elif args.command == "sync":
        sync_all()
        print(f"{GREEN}✅ Assets manifest and pubspec.yaml synchronized!{RESET}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

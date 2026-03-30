"""Parse and validate skill document structure."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

import yaml


@dataclass
class ParseValidateResult:
    """Result of parse validation."""

    yaml_score: int
    sections_score: int
    trigger_score: int
    placeholder_score: int
    security_pass: bool
    total_score: int
    yaml_details: dict = field(default_factory=dict)
    sections_details: dict = field(default_factory=dict)
    trigger_details: dict = field(default_factory=dict)
    placeholder_details: dict = field(default_factory=dict)
    security_details: dict = field(default_factory=dict)


def extract_yaml_frontmatter(content: str) -> dict:
    """Extract YAML frontmatter from markdown content.

    Args:
        content: Full markdown content including frontmatter.

    Returns:
        Dictionary of frontmatter key-value pairs.
    """
    pattern = r"^---\s*\n(.*?)\n---\s*\n"
    match = re.match(pattern, content, re.DOTALL)

    if not match:
        return {}

    yaml_content = match.group(1)

    try:
        data = yaml.safe_load(yaml_content) or {}
    except yaml.YAMLError:
        return {}

    return data


def check_yaml_frontmatter(frontmatter: dict) -> tuple[int, dict]:
    """Check YAML frontmatter for required fields.

    Args:
        frontmatter: Parsed frontmatter dictionary.

    Returns:
        Tuple of (score, details dict).
    """
    score = 0
    details = {
        "has_name": False,
        "has_description": False,
        "has_license": False,
    }

    if frontmatter.get("name"):
        score += 10
        details["has_name"] = True

    if frontmatter.get("description"):
        score += 10
        details["has_description"] = True

    if frontmatter.get("license"):
        score += 10
        details["has_license"] = True

    return score, details


def check_sections(content: str) -> tuple[int, dict]:
    """Check for three required sections §1.1, §1.2, §1.3.

    Args:
        content: Skill document content.

    Returns:
        Tuple of (score, details dict).
    """
    score = 0
    details = {
        "has_1_1": False,
        "has_1_2": False,
        "has_1_3": False,
    }

    if re.search(r"§1\.1[\s]", content):
        score += 10
        details["has_1_1"] = True

    if re.search(r"§1\.2[\s]", content):
        score += 10
        details["has_1_2"] = True

    if re.search(r"§1\.3[\s]", content):
        score += 10
        details["has_1_3"] = True

    return score, details


def check_triggers(content: str) -> tuple[int, dict]:
    """Check for trigger words CREATE, EVALUATE, RESTORE, TUNE.

    Args:
        content: Skill document content.

    Returns:
        Tuple of (score, details dict).
    """
    score = 0
    create_count = len(re.findall(r"CREATE", content, re.IGNORECASE))
    evaluate_count = len(re.findall(r"EVALUATE", content, re.IGNORECASE))
    restore_count = len(re.findall(r"RESTORE", content, re.IGNORECASE))
    tune_count = len(re.findall(r"TUNE", content, re.IGNORECASE))

    if create_count >= 5:
        score += 7
    if evaluate_count >= 5:
        score += 6
    if restore_count >= 5:
        score += 6
    if tune_count >= 5:
        score += 6

    return score, {
        "create_count": create_count,
        "evaluate_count": evaluate_count,
        "restore_count": restore_count,
        "tune_count": tune_count,
    }


def check_placeholders(content: str) -> tuple[int, dict]:
    """Check for placeholder text.

    Args:
        content: Skill document content.

    Returns:
        Tuple of (score, details dict).
    """
    placeholder_pattern = r"\[TODO\]|\[FIXME\]|TBD|undefined|null"
    matches = re.findall(placeholder_pattern, content, re.IGNORECASE)
    placeholder_count = len(matches)

    if placeholder_count == 0:
        score = 15
    elif placeholder_count <= 2:
        score = 10
    elif placeholder_count <= 5:
        score = 5
    else:
        score = 0

    return score, {"placeholder_count": placeholder_count}


def check_security(content: str) -> tuple[bool, dict]:
    """Check for security violations.

    Args:
        content: Skill document content.

    Returns:
        Tuple of (is_violation, details dict).
    """
    details = {
        "has_hardcoded_secret": False,
        "has_path_traversal": False,
    }

    secret_pattern = r"sk-[a-zA-Z0-9]{20,}|api_key|password\s*=|\btoken\s*="
    if re.search(secret_pattern, content):
        details["has_hardcoded_secret"] = True
        return True, details

    path_traversal_pattern = r"\.\.|\%00"
    if re.search(path_traversal_pattern, content):
        details["has_path_traversal"] = True
        return True, details

    return False, details


def parse_validate(skill_file: Path | str) -> ParseValidateResult:
    """Run full parse validation on a skill file.

    Args:
        skill_file: Path to SKILL.md file.

    Returns:
        ParseValidateResult with all scores and details.

    Raises:
        FileNotFoundError: If skill file does not exist.
    """
    skill_path = Path(skill_file)
    if not skill_path.exists():
        raise FileNotFoundError(f"File not found: {skill_file}")

    content = skill_path.read_text(encoding="utf-8")

    frontmatter = extract_yaml_frontmatter(content)
    yaml_score, yaml_details = check_yaml_frontmatter(frontmatter)

    sections_score, sections_details = check_sections(content)

    trigger_score, trigger_details = check_triggers(content)

    placeholder_score, placeholder_details = check_placeholders(content)

    security_violation, security_details = check_security(content)

    total_score = yaml_score + sections_score + trigger_score + placeholder_score

    return ParseValidateResult(
        yaml_score=yaml_score,
        sections_score=sections_score,
        trigger_score=trigger_score,
        placeholder_score=placeholder_score,
        security_pass=not security_violation,
        total_score=total_score,
        yaml_details=yaml_details,
        sections_details=sections_details,
        trigger_details=trigger_details,
        placeholder_details=placeholder_details,
        security_details=security_details,
    )

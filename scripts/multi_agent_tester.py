#!/usr/bin/env python3
"""Multi-Agent Skill Tester - 使用 Minimax 和 Kimi Code 循环测试 skill"""

import os
import json
import subprocess
import argparse
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional
import requests
import time
from functools import wraps


def retry_on_failure(max_retries=3, delay=1):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_retries - 1:
                        raise
                    print(f"Attempt {attempt + 1} failed: {e}, retrying...")
                    time.sleep(delay)
            return None

        return wrapper

    return decorator


@dataclass
class AgentConfig:
    api_key: str
    api_base: str = "https://api.minimax.chat/v1"
    model: str = "Minimax-Text-01"


@dataclass
class RoundResult:
    round_num: int
    minimax_skill: str
    minimax_eval: dict
    kimi_skill: str
    kimi_eval: dict
    issues: list = field(default_factory=list)


class MinimaxAgent:
    def __init__(self, config: AgentConfig):
        self.config = config

    @retry_on_failure(max_retries=3, delay=2)
    def _call_api(self, prompt: str, endpoint: str) -> str:
        response = requests.post(
            endpoint,
            headers={
                "Authorization": f"Bearer {self.config.api_key}",
                "Content-Type": "application/json",
            },
            json={"model": self.config.model, "messages": [{"role": "user", "content": prompt}]},
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]

    def create_evaluation_skill(self, round_num: int) -> str:
        prompt = f"""创建一个 evaluation skill，用于评估其他 skill 的质量。
        
要求:
- name: minimax_evaluator
- description: 使用 Minimax 模型评估 skill 质量
- 包含 evaluation 逻辑
- tier: BRONZE

只返回完整的 SKILL.md 内容。"""

        content = self._call_api(prompt, f"{self.config.api_base}/text/chatcompletion_v2")
        return self._extract_skill_md(content)

    def _extract_skill_md(self, text: str) -> str:
        """从响应中提取 SKILL.md 内容"""
        if "```markdown" in text:
            start = text.find("```markdown") + 11
            end = text.find("```", start)
            return text[start:end].strip()
        return text.strip()


class KimiAgent:
    def __init__(self, config: AgentConfig):
        self.config = config
        self.config.api_base = "https://api.moonshot.cn/v1"
        self.config.model = "moonshot-v1-8k"

    @retry_on_failure(max_retries=3, delay=2)
    def _call_api(self, prompt: str, endpoint: str) -> str:
        response = requests.post(
            endpoint,
            headers={
                "Authorization": f"Bearer {self.config.api_key}",
                "Content-Type": "application/json",
            },
            json={"model": self.config.model, "messages": [{"role": "user", "content": prompt}]},
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]

    def create_optimization_skill(self, round_num: int) -> str:
        prompt = f"""创建一个 optimization skill，用于优化其他 skill 的质量。
        
要求:
- name: kimi_optimizer
- description: 使用 Kimi 模型优化 skill 质量
- 包含 optimization 逻辑
- tier: BRONZE

只返回完整的 SKILL.md 内容。"""

        content = self._call_api(prompt, f"{self.config.api_base}/chat/completions")
        return self._extract_skill_md(content)

    def _extract_skill_md(self, text: str) -> str:
        if "```markdown" in text:
            start = text.find("```markdown") + 11
            end = text.find("```", start)
            return text[start:end].strip()
        return text.strip()


class SkillTester:
    CHECKPOINT_FILE = "eval_results/.checkpoint.json"

    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.round_num = 0
        self.minimax_agent = None
        self.kimi_agent = None

    def save_checkpoint(self, round_num: int):
        with open(self.CHECKPOINT_FILE, "w") as f:
            json.dump({"last_round": round_num}, f)

    def load_checkpoint(self) -> int:
        try:
            with open(self.CHECKPOINT_FILE) as f:
                return json.load(f)["last_round"]
        except:
            return 0

    def git_commit_if_issues(self, issues: list):
        critical_issues = [i for i in issues if i.get("severity") == "CRITICAL"]
        if critical_issues:
            subprocess.run(["git", "add", "eval_results/"], cwd=self.output_dir.parent)
            subprocess.run(
                [
                    "git",
                    "commit",
                    "-m",
                    f"fix: auto-fix critical issues from round {self.round_num}",
                ]
            )

    def run_skill_evaluate(self, skill_path: str) -> dict:
        result = subprocess.run(
            ["skill", "evaluate", skill_path], capture_output=True, text=True, timeout=60
        )
        if result.returncode != 0:
            return {
                "error": result.stderr,
                "stdout": result.stdout,
                "returncode": result.returncode,
            }
        try:
            lines = result.stdout.strip().split("\n")
            for line in lines:
                if line.startswith("{"):
                    return json.loads(line)
        except:
            pass
        return {"raw_output": result.stdout}

    def execute_round(self) -> RoundResult:
        self.round_num += 1
        round_dir = self.output_dir / f"round_{self.round_num:04d}"
        round_dir.mkdir(parents=True, exist_ok=True)

        minimax_skill_md = self.minimax_agent.create_evaluation_skill(self.round_num)
        minimax_skill_path = round_dir / "minimax_eval_skill.md"
        minimax_skill_path.write_text(minimax_skill_md)

        kimi_skill_md = self.kimi_agent.create_optimization_skill(self.round_num)
        kimi_skill_path = round_dir / "kimi_opt_skill.md"
        kimi_skill_path.write_text(kimi_skill_md)

        minimax_eval = self.run_skill_evaluate(str(minimax_skill_path))
        kimi_eval = self.run_skill_evaluate(str(kimi_skill_path))

        issues = self._check_issues(
            minimax_eval, kimi_eval, str(minimax_skill_path), str(kimi_skill_path)
        )

        self._save_results(round_dir, minimax_eval, kimi_eval, issues)

        return RoundResult(
            round_num=self.round_num,
            minimax_skill=str(minimax_skill_path),
            minimax_eval=minimax_eval,
            kimi_skill=str(kimi_skill_path),
            kimi_eval=kimi_eval,
            issues=issues,
        )

    def _check_issues(
        self, minimax_eval: dict, kimi_eval: dict, minimax_skill: str, kimi_skill: str
    ) -> list:
        issues = []

        for name, eval_result, skill_path in [
            ("minimax", minimax_eval, minimax_skill),
            ("kimi", kimi_eval, kimi_skill),
        ]:
            parse_result = self.run_skill_parse(skill_path)
            if parse_result.get("returncode", 0) != 0:
                issues.append(
                    {
                        "severity": "HIGH",
                        "source": name,
                        "type": "parse_error",
                        "message": parse_result.get("stderr", "Unknown parse error"),
                    }
                )

            validate_result = self.run_skill_validate(skill_path)
            if validate_result.get("returncode", 0) != 0:
                issues.append(
                    {
                        "severity": "MEDIUM",
                        "source": name,
                        "type": "validation_error",
                        "message": validate_result.get("stderr", "Unknown validation error"),
                    }
                )

            score = eval_result.get("total_score", 0)
            if score < 500:
                issues.append(
                    {
                        "severity": "HIGH",
                        "source": name,
                        "type": "low_score",
                        "message": f"Score too low: {score}",
                    }
                )

        return issues

    def run_skill_parse(self, skill_path: str) -> dict:
        result = subprocess.run(["skill", "parse", skill_path], capture_output=True, text=True)
        return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}

    def run_skill_validate(self, skill_path: str) -> dict:
        result = subprocess.run(["skill", "validate", skill_path], capture_output=True, text=True)
        return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}

    def _save_results(self, round_dir: Path, minimax_eval: dict, kimi_eval: dict, issues: list):
        with open(round_dir / "minimax_eval_result.json", "w") as f:
            json.dump(minimax_eval, f, indent=2)
        with open(round_dir / "kimi_opt_eval_result.json", "w") as f:
            json.dump(kimi_eval, f, indent=2)
        with open(round_dir / "issues.json", "w") as f:
            json.dump(issues, f, indent=2)

    def generate_report(self, output_dir: Path):
        report_path = output_dir / "report.html"

        with open(report_path, "w") as f:
            f.write("""<!DOCTYPE html>
<html>
<head>
    <title>Multi-Agent Skill Tester Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .issue { padding: 10px; margin: 5px 0; border-radius: 5px; }
        .CRITICAL { background: #ffcccc; }
        .HIGH { background: #ffe0cc; }
        .MEDIUM { background: #fff3cc; }
        .LOW { background: #e6ffcc; }
    </style>
</head>
<body>
    <h1>Multi-Agent Skill Tester Report</h1>
""")

            rounds = sorted(output_dir.glob("round_*"))
            for round_dir in rounds:
                issues_file = round_dir / "issues.json"
                if issues_file.exists():
                    with open(issues_file) as f_issues:
                        issues = json.load(f_issues)
                    f.write(f"<h2>Round {round_dir.name}</h2>")
                    for issue in issues:
                        severity = issue.get("severity", "LOW")
                        f.write(
                            f'<div class="issue {severity}">{severity}: {issue.get("message", "")}</div>'
                        )

            f.write("</body></html>")

        return report_path


def main():
    parser = argparse.ArgumentParser(description="Multi-Agent Skill Tester")
    parser.add_argument("--rounds", type=int, default=1000, help="Number of rounds to run")
    parser.add_argument("--output", type=str, default="eval_results", help="Output directory")
    args = parser.parse_args()

    output_dir = Path(args.output)
    tester = SkillTester(output_dir)

    minimax_config = AgentConfig(
        api_key=os.environ.get("MINIMAX_API_KEY", ""), api_base="https://api.minimax.chat/v1"
    )
    kimi_config = AgentConfig(
        api_key=os.environ.get("KIMI_API_KEY", ""), api_base="https://api.moonshot.cn/v1"
    )

    tester.minimax_agent = MinimaxAgent(minimax_config)
    tester.kimi_agent = KimiAgent(kimi_config)

    print(f"Starting {args.rounds} rounds of testing...")

    start_round = tester.load_checkpoint()
    print(f"Resuming from round {start_round + 1}")

    all_results = []
    for i in range(start_round, args.rounds):
        result = tester.execute_round()
        all_results.append(result)
        tester.save_checkpoint(result.round_num)

        if (i + 1) % 10 == 0:
            print(f"Completed round {i + 1}")
            tester.git_commit_if_issues(result.issues)

    summary = {
        "total_rounds": args.rounds,
        "results": [{"round": r.round_num, "issues": len(r.issues)} for r in all_results],
    }
    with open(output_dir / "summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    print("Generating report...")
    report_path = tester.generate_report(output_dir)
    print(f"Report saved to: {report_path}")

    print("Done!")


if __name__ == "__main__":
    main()

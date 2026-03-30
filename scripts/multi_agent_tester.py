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
                "Content-Type": "application/json"
            },
            json={
                "model": self.config.model,
                "messages": [{"role": "user", "content": prompt}]
            }
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
    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self.round_num = 0
        self.minimax_agent = None
        self.kimi_agent = None

    def run_skill_evaluate(self, skill_path: str) -> dict:
        result = subprocess.run(
            ["skill", "evaluate", skill_path],
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode != 0:
            return {
                "error": result.stderr,
                "stdout": result.stdout,
                "returncode": result.returncode
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

        issues = self._check_issues(minimax_eval, kimi_eval)

        self._save_results(round_dir, minimax_eval, kimi_eval, issues)

        return RoundResult(
            round_num=self.round_num,
            minimax_skill=str(minimax_skill_path),
            minimax_eval=minimax_eval,
            kimi_skill=str(kimi_skill_path),
            kimi_eval=kimi_eval,
            issues=issues,
        )

    def _check_issues(self, minimax_eval: dict, kimi_eval: dict) -> list:
        issues = []
        for name, eval_result in [("minimax", minimax_eval), ("kimi", kimi_eval)]:
            if "error" in eval_result:
                issues.append({"severity": "HIGH", "source": name, "message": eval_result["error"]})
            score = eval_result.get("total_score", 0)
            if score < 700:
                issues.append(
                    {"severity": "MEDIUM", "source": name, "message": f"Low score: {score}"}
                )
        return issues

    def _save_results(self, round_dir: Path, minimax_eval: dict, kimi_eval: dict, issues: list):
        with open(round_dir / "minimax_eval_result.json", "w") as f:
            json.dump(minimax_eval, f, indent=2)
        with open(round_dir / "kimi_opt_eval_result.json", "w") as f:
            json.dump(kimi_eval, f, indent=2)
        with open(round_dir / "issues.json", "w") as f:
            json.dump(issues, f, indent=2)


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

    all_results = []
    for i in range(args.rounds):
        result = tester.execute_round()
        all_results.append(result)

        if (i + 1) % 10 == 0:
            print(f"Completed round {i + 1}")

    summary = {
        "total_rounds": args.rounds,
        "results": [{"round": r.round_num, "issues": len(r.issues)} for r in all_results],
    }
    with open(output_dir / "summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    print("Done!")


if __name__ == "__main__":
    main()

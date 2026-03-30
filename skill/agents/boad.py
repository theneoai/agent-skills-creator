"""BOAD (Bandit Optimization for Agent Design) hierarchical agent discovery."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from enum import Enum
from typing import Protocol


class AgentTier(Enum):
    ORCHESTRATOR = "orchestrator"
    SPECIALIST = "specialist"
    EXECUTOR = "executor"


@dataclass
class AgentSpec:
    name: str
    tier: AgentTier
    capabilities: list[str]
    reward: float = 0.0
    visits: int = 0


class BOADOptimizer:
    def __init__(self, exploration_rate: float = 0.1) -> None:
        self.exploration_rate = exploration_rate
        self.agents: dict[AgentTier, list[AgentSpec]] = {
            AgentTier.ORCHESTRATOR: [],
            AgentTier.SPECIALIST: [],
            AgentTier.EXECUTOR: [],
        }
        self._counters: dict[AgentTier, int] = {
            AgentTier.ORCHESTRATOR: 0,
            AgentTier.SPECIALIST: 0,
            AgentTier.EXECUTOR: 0,
        }

    def _ucb1_score(self, agent: AgentSpec, total_visits: int) -> float:
        if agent.visits == 0:
            return float("inf")
        exploitation = agent.reward
        exploration = math.sqrt(2 * math.log(total_visits) / agent.visits)
        return exploitation + exploration

    def select_agent(self, task: str) -> AgentSpec:
        for tier in [AgentTier.ORCHESTRATOR, AgentTier.SPECIALIST, AgentTier.EXECUTOR]:
            if self.agents[tier]:
                if random.random() < self.exploration_rate:
                    return random.choice(self.agents[tier])
                total_visits = sum(a.visits for a in self.agents[tier])
                if total_visits == 0:
                    return self.agents[tier][0]
                return max(self.agents[tier], key=lambda a: self._ucb1_score(a, total_visits))
        raise ValueError("No agents available for selection")

    def update_reward(self, agent: AgentSpec, reward: float) -> None:
        agent.visits += 1
        agent.reward = (agent.reward * (agent.visits - 1) + reward) / agent.visits

    def get_hierarchy(self) -> dict[AgentTier, list[AgentSpec]]:
        return self.agents

    def suggest_new_agent(self, parent: AgentSpec | None) -> AgentSpec:
        if parent is None:
            tier = AgentTier.ORCHESTRATOR
        elif parent.tier == AgentTier.ORCHESTRATOR:
            tier = AgentTier.SPECIALIST
        elif parent.tier == AgentTier.SPECIALIST:
            tier = AgentTier.EXECUTOR
        else:
            raise ValueError("Executor cannot have children")

        self._counters[tier] += 1
        prefix = tier.value
        name = f"{prefix}-{self._counters[tier]}"
        return AgentSpec(name=name, tier=tier, capabilities=[])

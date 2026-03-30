"""Tests for BOAD hierarchical agent discovery."""

from __future__ import annotations

import pytest

from skill.agents.boad import AgentSpec, AgentTier, BOADOptimizer


class TestAgentTier:
    """Test suite for AgentTier enum."""

    def test_tier_values(self):
        """Test AgentTier has correct values."""
        assert AgentTier.ORCHESTRATOR.value == "orchestrator"
        assert AgentTier.SPECIALIST.value == "specialist"
        assert AgentTier.EXECUTOR.value == "executor"

    def test_tier_count(self):
        """Test AgentTier has exactly 3 tiers."""
        assert len(AgentTier) == 3


class TestAgentSpec:
    """Test suite for AgentSpec dataclass."""

    def test_create_agent_spec(self):
        """Test creating an AgentSpec."""
        agent = AgentSpec(
            name="test-agent",
            tier=AgentTier.SPECIALIST,
            capabilities=["coding", "debugging"],
        )
        assert agent.name == "test-agent"
        assert agent.tier == AgentTier.SPECIALIST
        assert agent.capabilities == ["coding", "debugging"]
        assert agent.reward == 0.0
        assert agent.visits == 0

    def test_agent_spec_defaults(self):
        """Test AgentSpec default values."""
        agent = AgentSpec(
            name="default-agent", tier=AgentTier.EXECUTOR, capabilities=[]
        )
        assert agent.reward == 0.0
        assert agent.visits == 0


class TestBOADOptimizerInit:
    """Test suite for BOADOptimizer initialization."""

    def test_default_exploration_rate(self):
        """Test default exploration rate is 0.1."""
        optimizer = BOADOptimizer()
        assert optimizer.exploration_rate == 0.1

    def test_custom_exploration_rate(self):
        """Test custom exploration rate."""
        optimizer = BOADOptimizer(exploration_rate=0.2)
        assert optimizer.exploration_rate == 0.2

    def test_initial_empty_hierarchy(self):
        """Test initial hierarchy is empty."""
        optimizer = BOADOptimizer()
        hierarchy = optimizer.get_hierarchy()
        assert hierarchy == {
            AgentTier.ORCHESTRATOR: [],
            AgentTier.SPECIALIST: [],
            AgentTier.EXECUTOR: [],
        }


class TestBOADOptimizerSelectAgent:
    """Test suite for BOADOptimizer.select_agent()."""

    def test_select_orchestrator(self):
        """Test selecting an orchestrator agent."""
        optimizer = BOADOptimizer()
        orchestrator = AgentSpec(
            name="orch-1",
            tier=AgentTier.ORCHESTRATOR,
            capabilities=["task-planning"],
        )
        optimizer.agents[AgentTier.ORCHESTRATOR].append(orchestrator)

        selected = optimizer.select_agent("complex-task")
        assert selected.tier == AgentTier.ORCHESTRATOR

    def test_select_with_exploration(self):
        """Test agent selection uses UCB1 for exploitation."""
        optimizer = BOADOptimizer(exploration_rate=0.0)
        agent1 = AgentSpec(
            name="agent-1",
            tier=AgentTier.SPECIALIST,
            capabilities=["a"],
            reward=10.0,
            visits=10,
        )
        agent2 = AgentSpec(
            name="agent-2",
            tier=AgentTier.SPECIALIST,
            capabilities=["b"],
            reward=0.0,
            visits=1,
        )
        optimizer.agents[AgentTier.SPECIALIST].extend([agent1, agent2])

        selected = optimizer.select_agent("task-a")
        assert selected.name == "agent-1"


class TestBOADOptimizerUpdateReward:
    """Test suite for BOADOptimizer.update_reward()."""

    def test_update_reward(self):
        """Test updating agent reward."""
        optimizer = BOADOptimizer()
        agent = AgentSpec(
            name="test-agent",
            tier=AgentTier.SPECIALIST,
            capabilities=[],
            reward=0.0,
            visits=0,
        )
        optimizer.agents[AgentTier.SPECIALIST].append(agent)

        optimizer.update_reward(agent, 1.0)

        assert agent.reward == 1.0
        assert agent.visits == 1

    def test_update_reward_multiple(self):
        """Test multiple reward updates."""
        optimizer = BOADOptimizer()
        agent = AgentSpec(
            name="test-agent",
            tier=AgentTier.SPECIALIST,
            capabilities=[],
            reward=0.0,
            visits=0,
        )
        optimizer.agents[AgentTier.SPECIALIST].append(agent)

        optimizer.update_reward(agent, 0.5)
        optimizer.update_reward(agent, 0.7)

        assert agent.reward == 0.6
        assert agent.visits == 2

    def test_update_reward_average(self):
        """Test reward represents average."""
        optimizer = BOADOptimizer()
        agent = AgentSpec(
            name="test-agent",
            tier=AgentTier.SPECIALIST,
            capabilities=[],
            reward=0.0,
            visits=0,
        )
        optimizer.agents[AgentTier.SPECIALIST].append(agent)

        optimizer.update_reward(agent, 1.0)
        optimizer.update_reward(agent, 3.0)

        assert agent.reward == 2.0
        assert agent.visits == 2


class TestBOADOptimizerSuggestNewAgent:
    """Test suite for BOADOptimizer.suggest_new_agent()."""

    def test_suggest_orchestrator(self):
        """Test suggesting an orchestrator when no parent."""
        optimizer = BOADOptimizer()
        agent = optimizer.suggest_new_agent(None)
        assert agent.tier == AgentTier.ORCHESTRATOR
        assert agent.name.startswith("orchestrator-")

    def test_suggest_specialist_for_orchestrator(self):
        """Test suggesting a specialist for orchestrator parent."""
        optimizer = BOADOptimizer()
        parent = AgentSpec(name="orch-1", tier=AgentTier.ORCHESTRATOR, capabilities=[])
        agent = optimizer.suggest_new_agent(parent)
        assert agent.tier == AgentTier.SPECIALIST
        assert agent.name.startswith("specialist-")

    def test_suggest_executor_for_specialist(self):
        """Test suggesting an executor for specialist parent."""
        optimizer = BOADOptimizer()
        parent = AgentSpec(name="spec-1", tier=AgentTier.SPECIALIST, capabilities=[])
        agent = optimizer.suggest_new_agent(parent)
        assert agent.tier == AgentTier.EXECUTOR
        assert agent.name.startswith("executor-")


class TestBOADOptimizerHierarchy:
    """Test suite for BOADOptimizer.get_hierarchy()."""

    def test_hierarchy_contains_all_tiers(self):
        """Test hierarchy contains all three tiers."""
        optimizer = BOADOptimizer()
        hierarchy = optimizer.get_hierarchy()
        assert set(hierarchy.keys()) == {
            AgentTier.ORCHESTRATOR,
            AgentTier.SPECIALIST,
            AgentTier.EXECUTOR,
        }

    def test_hierarchy_with_agents(self):
        """Test hierarchy returns all agents."""
        optimizer = BOADOptimizer()
        orch = AgentSpec(name="orch-1", tier=AgentTier.ORCHESTRATOR, capabilities=[])
        spec = AgentSpec(name="spec-1", tier=AgentTier.SPECIALIST, capabilities=[])
        exec_ = AgentSpec(name="exec-1", tier=AgentTier.EXECUTOR, capabilities=[])
        optimizer.agents[AgentTier.ORCHESTRATOR].append(orch)
        optimizer.agents[AgentTier.SPECIALIST].append(spec)
        optimizer.agents[AgentTier.EXECUTOR].append(exec_)

        hierarchy = optimizer.get_hierarchy()
        assert len(hierarchy[AgentTier.ORCHESTRATOR]) == 1
        assert len(hierarchy[AgentTier.SPECIALIST]) == 1
        assert len(hierarchy[AgentTier.EXECUTOR]) == 1

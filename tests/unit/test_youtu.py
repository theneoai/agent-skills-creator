import pytest
import time
from skill.agents.youtu import YoutuAgent
from skill.agents.evolution_memory import EvolutionMemory, MemoryEntry


class TestYoutuAgent:
    def test_init(self):
        memory = EvolutionMemory()
        agent = YoutuAgent(memory=memory)
        assert agent.memory is memory
        assert agent.exploration_rate == 0.1
        assert agent.collector is not None

    def test_practice_mode(self):
        memory = EvolutionMemory()
        memory.add(
            MemoryEntry(
                time.time(), "CREATE", [{"action": "step1"}], "success", 1.0, []
            )
        )
        agent = YoutuAgent(memory=memory)

        action = agent.practice("CREATE", {"task_type": "CREATE"})
        assert action.action_type == "practice"
        assert action.confidence > 0.5

    def test_decide_mode_practice(self):
        memory = EvolutionMemory()
        for i in range(3):
            memory.add(
                MemoryEntry(
                    time.time(), "CREATE", [{"action": f"step{i}"}], "success", 1.0, []
                )
            )
        agent = YoutuAgent(memory=memory)

        mode = agent.decide_mode({"task_type": "CREATE"})
        assert mode == "practice"

    def test_decide_mode_rl(self):
        memory = EvolutionMemory()
        memory.add(
            MemoryEntry(
                time.time(), "CREATE", [{"action": "step1"}], "success", 1.0, []
            )
        )
        agent = YoutuAgent(memory=memory)

        mode = agent.decide_mode({"task_type": "CREATE"})
        assert mode == "rl"

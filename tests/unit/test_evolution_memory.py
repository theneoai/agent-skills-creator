import pytest
import time
from skill.agents.evolution_memory import MemoryEntry, EvolutionMemory


class TestMemoryEntry:
    def test_create_entry(self):
        entry = MemoryEntry(
            timestamp=time.time(),
            task_type="CREATE",
            trajectory=[{"action": "step1", "result": "success"}],
            outcome="success",
            reward=1.0,
            lessons=["Lesson 1"],
        )
        assert entry.outcome == "success"
        assert entry.reward == 1.0


class TestEvolutionMemory:
    def test_get_successful_trajectories(self):
        memory = EvolutionMemory()
        memory.add(MemoryEntry(time.time(), "CREATE", [{"a": 1}], "success", 1.0, []))
        memory.add(MemoryEntry(time.time(), "CREATE", [{"b": 2}], "failure", 0.0, []))
        memory.add(MemoryEntry(time.time(), "CREATE", [{"c": 3}], "success", 0.9, []))

        result = memory.get_successful_trajectories("CREATE")
        assert len(result) == 2
        assert result[0] == [{"a": 1}]
        assert result[1] == [{"c": 3}]

    def test_get_successful_trajectories_empty(self):
        memory = EvolutionMemory()
        memory.add(MemoryEntry(time.time(), "CREATE", [{"a": 1}], "failure", 0.0, []))

        result = memory.get_successful_trajectories("CREATE")
        assert result == []

    def test_get_similar(self):
        memory = EvolutionMemory()
        memory.add(MemoryEntry(time.time(), "CREATE", [{"a": 1}], "success", 1.0, []))
        memory.add(MemoryEntry(time.time(), "CREATE", [{"a": 2}], "success", 0.8, []))
        memory.add(MemoryEntry(time.time(), "EVALUATE", [{"a": 3}], "success", 0.9, []))

        similar = memory.get_similar("CREATE", k=2)
        assert len(similar) == 2
        assert similar[0].trajectory == [{"a": 1}]
        assert similar[1].trajectory == [{"a": 2}]

    def test_get_similar_k_limits_results(self):
        memory = EvolutionMemory()
        for i in range(5):
            memory.add(
                MemoryEntry(time.time(), "CREATE", [{"n": i}], "success", 1.0, [])
            )

        similar = memory.get_similar("CREATE", k=3)
        assert len(similar) == 3

    def test_get_similar_no_matches(self):
        memory = EvolutionMemory()
        memory.add(MemoryEntry(time.time(), "CREATE", [{"a": 1}], "success", 1.0, []))

        similar = memory.get_similar("EVALUATE", k=5)
        assert similar == []

    def test_get_similar_empty_memory(self):
        memory = EvolutionMemory()

        similar = memory.get_similar("CREATE", k=5)
        assert similar == []

import pytest
from skill.orchestrator.loongflow import LoongFlowOrchestrator
from skill.agents.evolution_memory import EvolutionMemory


class TestLoongFlowOrchestrator:
    def test_init(self):
        memory = EvolutionMemory()
        orchestrator = LoongFlowOrchestrator(memory=memory)
        assert orchestrator.memory is memory

    def test_run_full_loop(self):
        memory = EvolutionMemory()
        orchestrator = LoongFlowOrchestrator(memory=memory)
        result = orchestrator.run("Create a weather skill")
        assert result.success is True
        completed = orchestrator.collector.get_completed()
        assert len(completed) == 1
        assert completed[0].task_type == "CREATE"
        assert completed[0].outcome == "success"

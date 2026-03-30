from __future__ import annotations
from typing import Any
import time
from skill.orchestrator.cognitive_graph import CognitiveGraph, CognitiveNode
from skill.agents.evolution_memory import EvolutionMemory, MemoryEntry
from skill.agents.trajectory import TrajectoryCollector


class ExecutionResult:
    def __init__(self, success: bool, output: Any = None, error: str | None = None):
        self.success = success
        self.output = output
        self.error = error


class MemoryUpdate:
    pass


class LoongFlowOrchestrator:
    def __init__(self, memory: EvolutionMemory) -> None:
        self.memory = memory
        self.collector = TrajectoryCollector()

    def plan(self, task: str) -> CognitiveGraph:
        graph = CognitiveGraph()
        root = CognitiveNode(
            id="root",
            type="task",
            content=task,
        )
        graph.add_node(root)
        return graph

    def execute(self, graph: CognitiveGraph) -> ExecutionResult:
        return ExecutionResult(success=True, output={})

    def summarize(self, result: ExecutionResult, graph: CognitiveGraph) -> MemoryUpdate:
        entry = MemoryEntry(
            timestamp=time.time(),
            task_type="CREATE",
            trajectory=[
                {"phase": "plan", "graph_nodes": len(graph.nodes)},
                {"phase": "execute", "success": result.success},
            ],
            outcome="success" if result.success else "failure",
            reward=1.0 if result.success else 0.0,
            lessons=[],
        )
        self.memory.add(entry)
        return MemoryUpdate()

    def run(self, task: str) -> ExecutionResult:
        session_id = self.collector.start_collection("CREATE", {"task": task})

        try:
            graph = self.plan(task)
            self.collector.record_action(
                session_id, {"phase": "plan", "graph_nodes": len(graph.nodes)}
            )

            result = self.execute(graph)
            self.collector.record_action(
                session_id, {"phase": "execute", "success": result.success}
            )

            self.summarize(result, graph)
            self.collector.record_action(session_id, {"phase": "summarize"})

            self.collector.end_collection(session_id, "success" if result.success else "failure")
            return result
        finally:
            if session_id in self.collector._active_sessions:
                self.collector.end_collection(session_id, "failure")

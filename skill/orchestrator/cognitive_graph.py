from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class CognitiveNode:
    id: str
    type: str
    content: str
    status: str = "pending"
    children: list[str] = field(default_factory=list)
    parent: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass
class CognitiveGraph:
    nodes: dict[str, CognitiveNode] = field(default_factory=dict)
    root: str | None = None
    edges: list[tuple[str, str]] = field(default_factory=list)

    def add_node(self, node: CognitiveNode) -> None:
        self.nodes[node.id] = node
        if self.root is None:
            self.root = node.id

    def add_edge(self, parent_id: str, child_id: str) -> None:
        self.edges.append((parent_id, child_id))
        if parent_id in self.nodes:
            self.nodes[parent_id].children.append(child_id)
        if child_id in self.nodes:
            self.nodes[child_id].parent = parent_id

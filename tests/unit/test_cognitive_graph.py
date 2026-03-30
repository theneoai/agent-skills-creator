from skill.orchestrator.cognitive_graph import CognitiveNode, CognitiveGraph


class TestCognitiveNode:
    def test_create_node(self):
        node = CognitiveNode(
            id="node-1",
            type="task",
            content="Test task",
            status="pending",
        )
        assert node.id == "node-1"
        assert node.type == "task"
        assert node.status == "pending"
        assert node.children == []
        assert node.parent is None

    def test_node_with_children(self):
        node = CognitiveNode(
            id="parent",
            type="task",
            content="Parent",
            children=["child-1", "child-2"],
            parent=None,
        )
        assert node.children == ["child-1", "child-2"]


class TestCognitiveGraph:
    def test_add_node(self):
        graph = CognitiveGraph()
        node = CognitiveNode(id="n1", type="task", content="test")
        graph.add_node(node)
        assert "n1" in graph.nodes
        assert graph.root == "n1"

    def test_add_edge(self):
        graph = CognitiveGraph()
        parent = CognitiveNode(id="p", type="task", content="parent")
        child = CognitiveNode(id="c", type="task", content="child")
        graph.add_node(parent)
        graph.add_node(child)
        graph.add_edge("p", "c")
        assert ("p", "c") in graph.edges
        assert "c" in parent.children
        assert child.parent == "p"

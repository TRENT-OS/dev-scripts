#!/usr/bin/env python3

# https://graphviz.readthedocs.io/en/stable/api.html

import graphviz

if __name__ == "__main__":

    g = graphviz.Digraph('grm2',
        format='pdf',
        graph_attr={'rankdir': 'LR'},
        node_attr={'color': 'lightblue2', 'style': 'filled'})

    g.node('node0')
    g.node('node1')
    g.node('node2')
    g.node('node3')
    g.node('node4')
    g.node('node5')
    g.node('node6')

    g.edge('node0', 'node1')
    g.edge('node0', 'node2')
    g.edge('node0', 'node3')
    g.edge('node3', 'node4')
    g.edge('node3', 'node5')
    g.edge('node3', 'node6')

    g.view(filename='grm2', cleanup=True)

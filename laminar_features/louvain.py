"""
Pure Python implementation of the Louvain algorithm.
Converted from Cython implementation.
Author: Alexandre Hollocou <alexandre@hollocou.fr>
License: BSD 3 clause
"""

import numpy as np
from scipy import sparse
import networkx as nx
from collections import defaultdict


class PythonLouvain:
    """Python implementation of the Louvain community detection algorithm."""

    def __init__(self, adj_matrix):
        """
        Initialize with a sparse adjacency matrix.

        Parameters:
        -----------
        adj_matrix : scipy.sparse matrix
            Sparse adjacency matrix of the graph
        """
        # Stopping criteria
        self._PASS_MAX = -1
        self._MIN = 0.0000001

        # Initialize graph
        self.n_nodes = adj_matrix.shape[0]
        self.graph_neighbors = [[] for _ in range(self.n_nodes)]
        self.graph_weights = [[] for _ in range(self.n_nodes)]

        # Copy graph from sparse matrix
        indptr = adj_matrix.indptr
        indices = adj_matrix.indices
        data = np.array(adj_matrix.data, dtype=float)

        for i in range(len(indptr) - 1):
            for j in range(indptr[i], indptr[i + 1]):
                self.graph_neighbors[i].append(indices[j])
                self.graph_weights[i].append(data[j])

        # Status variables
        self.communities = []
        self.node2com = None
        self.internals = None
        self.loops = None
        self.degrees = None
        self.gdegrees = None
        self.total_weight = 0.

        # List of partitions
        self.partition_list = []

    def init_status(self):
        """Initialize internal state variables."""
        self.node2com = np.arange(self.n_nodes, dtype=int)
        self.internals = np.zeros(self.n_nodes, dtype=float)
        self.loops = np.zeros(self.n_nodes, dtype=float)
        self.degrees = np.zeros(self.n_nodes, dtype=float)
        self.gdegrees = np.zeros(self.n_nodes, dtype=float)
        self.total_weight = 0.

        # Fill internal state variables
        for node in range(self.n_nodes):
            for i, neighbor in enumerate(self.graph_neighbors[node]):
                neighbor_weight = self.graph_weights[node][i]

                if neighbor == node:
                    self.internals[node] += neighbor_weight
                    self.loops[node] += neighbor_weight
                    self.degrees[node] += 2. * neighbor_weight
                    self.gdegrees[node] += 2. * neighbor_weight
                    self.total_weight += 2. * neighbor_weight
                else:
                    self.degrees[node] += neighbor_weight
                    self.gdegrees[node] += neighbor_weight
                    self.total_weight += neighbor_weight

        self.total_weight = self.total_weight / 2.

    def remove(self, node, com, weight):
        """Remove node from its community."""
        self.node2com[node] = -1
        self.degrees[com] -= self.gdegrees[node]
        self.internals[com] -= weight + self.loops[node]

    def insert(self, node, com, weight):
        """Insert node into a community."""
        self.node2com[node] = com
        self.degrees[com] += self.gdegrees[node]
        self.internals[com] += weight + self.loops[node]

    def modularity(self, resolution):
        """Compute the modularity of the current partition."""
        result = 0.
        for com in range(self.n_nodes):
            result += resolution * self.internals[com] / self.total_weight
            result -= (self.degrees[com] / (2. * self.total_weight)) ** 2
        return result

    def neighcom(self, node):
        """Get weights to neighboring communities for a node."""
        neighbor_weight = defaultdict(float)
        for i, neighbor in enumerate(self.graph_neighbors[node]):
            if neighbor != node:
                neighborcom = self.node2com[neighbor]
                neighbor_weight[neighborcom] += self.graph_weights[node][i]
        return neighbor_weight

    def one_level(self, resolution):
        """Perform one level of community detection."""
        modified = True
        nb_pass_done = 0
        cur_mod = self.modularity(resolution)
        new_mod = cur_mod

        while modified and nb_pass_done != self._PASS_MAX:
            cur_mod = new_mod
            modified = False
            nb_pass_done += 1

            for node in range(self.n_nodes):
                node_com = self.node2com[node]
                neighbor_weight = self.neighcom(node)

                # Remove node from its community
                self.remove(node, node_com, neighbor_weight[node_com])

                # Find best community
                best_com = node_com
                best_increase = 0.

                for com, weight in neighbor_weight.items():
                    if weight > 0:
                        increase = (resolution * weight -
                                  self.degrees[com] * self.gdegrees[node] /
                                  (self.total_weight * 2.))
                        if increase > best_increase:
                            best_increase = increase
                            best_com = com

                # Insert node into best community
                self.insert(node, best_com, neighbor_weight[best_com])

                if best_com != node_com:
                    modified = True

            new_mod = self.modularity(resolution)
            if new_mod - cur_mod < self._MIN:
                break

    def renumber(self):
        """Renumber communities to be consecutive integers."""
        # Count nodes in each community
        com_n_nodes = [0] * self.n_nodes
        for node in range(self.n_nodes):
            com_n_nodes[self.node2com[node]] += 1

        # Create new indices for non-empty communities
        com_new_index = [0] * self.n_nodes
        final_index = 0
        for com in range(self.n_nodes):
            if com_n_nodes[com] > 0:
                com_new_index[com] = final_index
                final_index += 1

        # Build new communities
        new_communities = [[] for _ in range(final_index)]
        new_node2com = np.zeros(self.n_nodes, dtype=int)

        for node in range(self.n_nodes):
            new_com = com_new_index[self.node2com[node]]
            new_communities[new_com].append(node)
            new_node2com[node] = new_com

        self.communities = new_communities
        self.node2com = new_node2com

    def induced_graph(self):
        """Create induced graph from current communities."""
        new_n_nodes = len(self.communities)
        new_graph_neighbors = [[] for _ in range(new_n_nodes)]
        new_graph_weights = [[] for _ in range(new_n_nodes)]

        for com in range(new_n_nodes):
            to_insert = defaultdict(float)

            for node in self.communities[com]:
                for i, neighbor in enumerate(self.graph_neighbors[node]):
                    neighbor_com = self.node2com[neighbor]
                    neighbor_weight = self.graph_weights[node][i]

                    if neighbor == node:
                        to_insert[neighbor_com] += 2 * neighbor_weight
                    else:
                        to_insert[neighbor_com] += neighbor_weight

            for neighbor_com, weight in to_insert.items():
                new_graph_neighbors[com].append(neighbor_com)
                if neighbor_com == com:
                    new_graph_weights[com].append(weight / 2.)
                else:
                    new_graph_weights[com].append(weight)

        self.n_nodes = new_n_nodes
        self.graph_neighbors = new_graph_neighbors
        self.graph_weights = new_graph_weights

    def get_partition(self):
        """Get current partition as a list."""
        return list(self.node2com)

    def generate_dendrogram(self, resolution=1.0):
        """
        Generate dendrogram by iteratively detecting communities.

        Parameters:
        -----------
        resolution : float
            Resolution parameter for modularity

        Returns:
        --------
        list of lists
            Dendrogram showing hierarchy of community assignments
        """
        self.init_status()
        self.one_level(resolution)
        new_mod = self.modularity(resolution)
        self.renumber()
        self.partition_list.append(self.get_partition())
        mod = new_mod
        self.induced_graph()
        self.init_status()

        while True:
            self.one_level(resolution)
            new_mod = self.modularity(resolution)

            if new_mod - mod < self._MIN:
                break

            self.renumber()
            self.partition_list.append(self.get_partition())
            mod = new_mod
            self.induced_graph()
            self.init_status()

        return self.partition_list


def python_modularity(partition, adj_matrix, resolution=1.0):
    """
    Compute modularity of a partition.

    Parameters:
    -----------
    partition : array-like
        Community assignment for each node
    adj_matrix : scipy.sparse matrix
        Sparse adjacency matrix
    resolution : float
        Resolution parameter

    Returns:
    --------
    float
        Modularity value
    """
    n_nodes = adj_matrix.shape[0]
    indptr = adj_matrix.indptr
    indices = adj_matrix.indices
    data = np.array(adj_matrix.data, dtype=float)

    # Convert partition to list
    part = list(partition)

    # Compute degrees
    links = 0.
    degrees = []

    for node in range(n_nodes):
        degree = 0.
        for i in range(indptr[node], indptr[node + 1]):
            if indices[i] == node:
                degree += 2 * data[i]
                links += 2 * data[i]
            else:
                degree += data[i]
                links += data[i]
        degrees.append(degree)

    links /= 2

    # Compute internal edges and degrees per community
    inc = defaultdict(float)
    deg = defaultdict(float)

    for node in range(n_nodes):
        com = part[node]
        deg[com] += degrees[node]

        for i in range(indptr[node], indptr[node + 1]):
            neighbor = indices[i]
            edge_weight = data[i]

            if part[neighbor] == com:
                if neighbor == node:
                    inc[com] += float(edge_weight)
                else:
                    inc[com] += float(edge_weight) / 2.

    # Compute modularity
    res = 0.
    for com in deg:
        res += resolution * (inc[com] / links) - (deg[com] / (2. * links)) ** 2

    return res


def best_partition(graph, resolution=1.):
    """
    Given a graph, compute a partition of the nodes
    using the Louvain heuristic to maximize the modularity function.

    Parameters
    ----------
    graph: networkx.Graph, scipy.csr_matrix or np.ndarray
        The input graph or its adjacency matrix (sparse or dense).

    resolution: double, optional, default: 1.0
        The resolution parameter that controls the size of the communities.
        This parameter corresponds to the time introduced in
        "Laplacian Dynamics and Multiscale Modular Structure in Networks",
        R. Lambiotte, J.-C. Delvenne, M. Barahona

    Returns
    -------
    partition: dictionary
        The output partition, with communities numbered from 0 to the number of communities.
        The keys of the dictionary correspond to the nodes and the values to the communities.

    References
    ----------

    - Fast unfolding of communities in large networks, 2008
      Blondel, Vincent D and Guillaume, Jean-Loup and Lambiotte, Renaud and Lefebvre, Etienne
      Journal of statistical mechanics: theory and experiment, 2008(10), P10008.

    Notes
    -----
    Uses a pure Python version of the Louvain algorithm.

    """
    if type(graph) == sparse.csr_matrix:
        adj_matrix = graph
    elif type(graph) == np.ndarray:
        adj_matrix = sparse.csr_matrix(graph)
    elif type(graph) == nx.classes.graph.Graph:
        adj_matrix = nx.adj_matrix(graph)
    else:
        raise TypeError(
            "The argument should be a NetworkX graph, a NumPy array or a SciPy Compressed Sparse Row matrix.")

    louvain = PythonLouvain(adj_matrix)
    dendrogram = louvain.generate_dendrogram(resolution)

    partition = range(len(dendrogram[-1]))
    for i in range(1, len(dendrogram) + 1):
        new_partition = dict()
        for j in range(len(dendrogram[-i])):
            new_partition[j] = partition[dendrogram[-i][j]]
        partition = new_partition

    if type(graph) == nx.classes.graph.Graph:
        return {node: partition[i] for (i, node) in enumerate(graph.nodes())}
    else:
        return partition


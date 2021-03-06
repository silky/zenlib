"""
This module provides functions that measure of degree distributions within a network.
"""

from zen.graph cimport Graph
from zen.digraph cimport DiGraph
from zen.exceptions import *
from zen.constants import *
import numpy as np
cimport numpy as np
import numpy.ma as ma

__all__ = ['cddist','ddist']

cpdef np.ndarray[np.float_t, ndim=1] cddist(G,direction=None,bint inverse=False):
	"""
	Return the cumulative degree distribution of the graph: a numpy
	array, C, where C[i] is the fraction of nodes with degree <= i.
	
	If G is a directed graph and direction is IN_DIR or OUT_DIR, then the
	cumulative distribution will be done with respect to the direction.
	
	If inverse is True, then C[i] is the fraction of nodes with degree >= i.
	"""
	cdef np.ndarray[np.float_t, ndim=1] R = ddist(G,direction,False)
	cdef float seen = 0
	cdef float nnodes = len(G)
	cdef int i
	cdef float x
	
	if inverse:
		seen = nnodes
		for i in range(len(R)):
			x = R[i]
			R[i] = seen / nnodes
			seen -= x
	else:
		for i in range(len(R)):
			seen += R[i]
			R[i] = seen / nnodes
			
	return R

cpdef ddist(G,direction=None,bint normalize=True):
	"""
	Return the degree distribution of the graph - a numpy float array, D, where D[i] is the fraction of nodes with degree i.
	
	If G is a directed graph and direction is IN_DIR or OUT_DIR, then the
	distribution will be done with respect to the direction.
	
	If normalize is False, then D[i] is the number of nodes with degree i.
	"""
	if not G.is_directed() and direction != None:
		raise ZenException, 'Direction cannot be specified for an undirected graph: %s' % direction
		
	if type(G) == Graph:
		return ug_ddist(<Graph> G,normalize)
	elif type(G) == DiGraph:
		return dg_ddist(<DiGraph> G,direction,normalize)
	else:
		raise InvalidGraphTypeException, 'Unknown graph type: %s' % str(type(G))
		
cdef ug_ddist(Graph G,bint normalize):
	cdef int degree,max_degree
	cdef int i
	cdef np.ndarray[np.float_t, ndim=1] dd
	cdef float nnodes
	
	# find the max degree
	max_degree = 0
	for i in range(G.next_node_idx):
		if G.node_info[i].exists:
			degree = G.degree_(i)
			if degree > max_degree:
				max_degree = degree
				
	# compute the degree distribution
	dd = np.zeros( max_degree + 1, np.float )
	
	for i in range(G.next_node_idx):
		if G.node_info[i].exists:
			dd[G.degree_(i)] += 1

	if normalize:
		nnodes = len(G)
		for i in range(max_degree+1):
			dd[i] = dd[i] / nnodes
			
	return dd

cdef dg_ddist(DiGraph G,direction,bint normalize):
	cdef int degree,max_degree
	cdef int i
	cdef np.ndarray[np.float_t, ndim=1] dd
	cdef float nnodes
	
	if direction is None or direction == BOTH_DIR:
		# find the max degree
		max_degree = 0
		for i in range(G.next_node_idx):
			if G.node_info[i].exists:
				degree = G.degree_(i)
				if degree > max_degree:
					max_degree = degree

		# compute the degree distribution
		dd = np.zeros( max_degree + 1, np.float )

		for i in range(G.next_node_idx):
			if G.node_info[i].exists:
				dd[G.degree_(i)] += 1

		if normalize:
			nnodes = len(G)
			for i in range(max_degree+1):
				dd[i] = dd[i] / nnodes

		return dd
	elif direction == IN_DIR:
		# find the max degree
		max_degree = 0
		for i in range(G.next_node_idx):
			if G.node_info[i].exists:
				degree = G.in_degree_(i)
				if degree > max_degree:
					max_degree = degree

		# compute the degree distribution
		dd = np.zeros( max_degree + 1, np.float )

		for i in range(G.next_node_idx):
			if G.node_info[i].exists:
				dd[G.in_degree_(i)] += 1

		if normalize:
			nnodes = len(G)
			for i in range(max_degree+1):
				dd[i] = dd[i] / nnodes

		return dd
	elif direction == OUT_DIR:
		# find the max degree
		max_degree = 0
		for i in range(G.next_node_idx):
			if G.node_info[i].exists:
				degree = G.out_degree_(i)
				if degree > max_degree:
					max_degree = degree

		# compute the degree distribution
		dd = np.zeros( max_degree + 1, np.float )

		for i in range(G.next_node_idx):
			if G.node_info[i].exists:
				dd[G.out_degree_(i)] += 1

		if normalize:
			nnodes = len(G)
			for i in range(max_degree+1):
				dd[i] = dd[i] / nnodes

		return dd
	else:
		raise ZenException, 'Invalid direction: %s' % direction
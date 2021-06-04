<template>
  <div id="app">
    <div class="sidebar">
      <div v-for="node in scopeNodePathObjects" :key="node.node_id" class="path-part">
        <span v-if="node !== scopeNode" class="node active" @click="goToNode(node.node_id)">{{ node.name }}</span>
        <span v-else class="node">{{ node.name }}</span>
        <span v-if="node !== scopeNode" class="sep">&gt;</span>
      </div>
      <h3>Selected Nodes</h3>
      <div v-for="nodeId in selectedNodes" :key="nodeId" class="node-details">
        <span class="node-name" @click="goToNode(nodeId)">{{ nodes[nodeId].name }}</span>
        <span class="node-count">{{ mappings.mappings.filter(x => x.node_id === nodeId).reduce((acu, x) => acu + x.count, 0) }}</span>
        <div><b>Lat, Lng: </b>{{ nodes[nodeId].lat }},{{ nodes[nodeId].lng }}</div>
        <div><b>ISO code: </b>{{ nodes[nodeId].iso_code }}</div>
        <div class="primary-selector"><b>Primary:</b><input type="radio" v-model="primaryNode" :value="nodeId"></div>
      </div>
      <button v-if="selectedNodes.length > 1" @click="mergeSelected" class="merge-button">Merge</button>
      <h3>Edit Node</h3>
      <div v-if="selectedNodes.length == 1" class="node-details">
        <div><b>Name: </b><input type="text" ref="editName" :value="nodes[selectedNodes[0]].name"></div>
        <div><b>Lat: </b><input type="text" ref="editLat" :value="nodes[selectedNodes[0]].lat"></div>
        <div><b>Lng: </b><input type="text" ref="editLng" :value="nodes[selectedNodes[0]].lng"></div>
        <div><b>ISO code: </b><input type="text" ref="editISO" :value="nodes[selectedNodes[0]].iso_code"></div>
        <button @click="saveEdit">Save</button>
      </div>
      <span v-else>Select one node to edit</span>
      <h3>Save results</h3>
      <button v-if="scopeNode" @click="save">Save</button>
      <span>{{ saveStatus }}</span>
      <h3>Options</h3>
      <div><b>Number of visible edges:</b><input type="number" min=0 v-model="edgesCount"></div>
      <div><b>Number of all edges:</b><input type="number" min=0 v-model="nodesCount"></div>
      <div><b>Display empty nodes:</b><input type="checkbox" v-model="displayEmptyNodes"></div>
      <div><b>Display between empty and complete nodes:</b><input type="checkbox" v-model="displayEdgeEmptyComplete"></div>
      <div><b>Display between two complete nodes:</b><input type="checkbox" v-model="displayEdgeTwoComplete"></div>
    </div>
    <div ref="graph" class="graph"></div>
  </div>
</template>
<script>
import { DataSet } from 'vis-data'
import { Network } from 'vis-network'

export default {
  name: 'App',
  data () {
    return {
      nodes: null,
      scopeNodePath: [1], // 1 = World (root node)
      mappings: null,
      selectedNodes: [],
      graphData: null,
      saveStatus: null,
      edgesCount: 30,
      nodesCount: 1000,
      displayEmptyNodes: true,
      displayEdgeEmptyComplete: true,
      displayEdgeTwoComplete: true,
      updatedNodes: [],
      primaryNode: null,
      api: null
    }
  },
  created () {
    this.api = new URLSearchParams(window.location.search).get('api')
    this.$http.get(this.api + '/nodes').then(response => {
      this.nodes = response.body.reduce((acu, x) => ({ ...acu, [x.node_id]: x }), {})
    }).catch(console.error)
  },
  watch: {
    scopeNode (newValue) {
      this.mappings = null
      this.selectedNodes = []
      this.saveStatus = null
      this.$http.get(this.api + '/task/' + newValue.node_id).then(response => {
        if (this.scopeNode.node_id !== newValue.node_id) return
        this.mappings = response.body
      })
    },
    selectedRegion (newValue) {
      this.countryData = null
      this.selectedNodes = []
      this.saveStatus = null
      this.$http.get(this.api + 'task/' + newValue.continent + '/' + newValue.country).then(response => {
        if (this.selectedRegion !== newValue) return
        this.countryData = response.body
      })
    },
    graphData () {
      if (!this.graphData) return
      this.graph = new Network(this.$refs.graph, this.graphData, {})
      this.graph.on('click', e => {
        if (e.nodes.length === 0) {
          this.selectedNodes = []
          return
        }
        const clicked = parseInt(e.nodes[0])
        if (this.selectedNodes.includes(clicked)) {
          this.selectedNodes = this.selectedNodes.filter(n => n !== clicked)
        } else {
          this.selectedNodes.push(clicked)
        }
      })
      this.updateColors()
    },
    selectedNodes () {
      if (this.primaryNode && !this.selectedNodes.includes(this.primaryNode)) this.primaryNode = null
      this.updateColors()
    },
    transformedData (newVal, oldVal) {
      oldVal = oldVal || { nodes: [], edges: [] }
      newVal = newVal || { nodes: [], edges: [] }
      if (!this.graphData) {
        this.graphData = { nodes: new DataSet(newVal.nodes), edges: new DataSet(newVal.edges) }
        return
      }
      const oldIds = oldVal.nodes.map(node => node.id)
      const newIds = newVal.nodes.map(node => node.id)
      const added = newVal.nodes.filter(node => !oldIds.includes(node.id))
      const deleted = oldVal.nodes.filter(node => !newIds.includes(node.id))
      const keeped = newVal.nodes.filter(node => oldIds.includes(node.id))
      deleted.forEach(node => this.graphData.nodes.remove({ id: node.id }))
      added.forEach(node => this.graphData.nodes.add(node))
      keeped.forEach(node => this.graphData.nodes.update(node))
      this.graphData.edges.forEach(edge => this.graphData.edges.remove(edge))
      newVal.edges.forEach(edge => this.graphData.edges.add(edge))
      this.updateColors()
    }
  },
  computed: {
    scopeNodePathObjects () {
      if (!this.nodes) return []
      return this.scopeNodePath.map(id => this.nodes[id] || {})
    },
    scopeNode () {
      if (!this.scopeNodePathObjects) return null
      return this.scopeNodePathObjects[this.scopeNodePathObjects.length - 1]
    },
    transformedData () {
      if (!this.mappings) return
      // Find all simple names for each node
      const groups = this.mappings.mappings.reduce((acu, v) => {
        acu[v.node_id] = [...(acu[v.node_id] || []), v.simple_name]
        return acu
      }, {})
      // Create graph node
      let nodes = Object.entries(groups).map(([nodeId, simpleNames]) => ({
        id: nodeId,
        label: this.nodes[nodeId].name + '\n-------------\n' + simpleNames.join('\n')
      }))
      // Filter out epty nodes
      if (!this.displayEmptyNodes) nodes = nodes.filter(x => this.nodesAggregatedCount[x.id] > 0)

      let edges = this.mappings.similarity
      // Map from simple name to node id
      const simpleToNodeId = this.mappings.mappings.reduce((acu, v) => ({ ...acu, [v.simple_name]: v.node_id }), {})
      // Replace simple names in edges definition to node ids
      edges = edges.map(edge => ({ ...edge, a: simpleToNodeId[edge.a], b: simpleToNodeId[edge.b] })).filter(x => x.a !== x.b && x.a && x.b)
      // Do not display edges between empty nodes
      edges = edges.filter(x => this.nodesAggregatedCount[x.a] > 0 || this.nodesAggregatedCount[x.b] > 0)
      if (!this.displayEdgeEmptyComplete) edges = edges.filter(x => !((this.isCompleteNode(x.a) && this.nodesAggregatedCount[x.b] === 0) || (this.isCompleteNode(x.b) && this.nodesAggregatedCount[x.a] === 0)))
      if (!this.displayEdgeTwoComplete) edges = edges.filter(x => !this.isCompleteNode(x.a) || !this.isCompleteNode(x.b))
      // Create similarity matrix between nodes
      // Because one node has multiple simple names, than there are multiple edges
      const edgesMap = {}
      edges.forEach(edge => {
        const nds = [edge.a, edge.b]
        nds.sort()
        edgesMap[nds[0]] = edgesMap[nds[0]] || {}
        edgesMap[nds[0]][nds[1]] = (edgesMap[nds[0]][nds[1]] || 0) < edge.similarity ? edge.similarity : (edgesMap[nds[0]][nds[1]] || 0)
      })
      // Transform back to list of edges
      edges = Object.keys(edgesMap).map(a => Object.keys(edgesMap[a]).map(b => ({ a, b, similarity: edgesMap[a][b] }))).flat()
      // Sort list by similarity
      edges.sort((a, b) => b.similarity - a.similarity)
      // Keep only nodes that are connected by one of first nodesCount edges
      const visibleNodes = [...new Set(edges.slice(0, this.nodesCount).map(e => ([e.a, e.b])).flat())]
      nodes = nodes.filter(n => visibleNodes.includes(n.id))
      // Keep edgesCount edges visible
      edges = edges.slice(0, this.edgesCount).map(x => ({ from: x.a, to: x.b, length: 150 + 100 * (1 - x.similarity) }))
      return { nodes, edges }
    },
    nodesAggregatedCount () {
      if (!this.mappings) return {}
      const agg = {}
      this.mappings.mappings.forEach(x => {
        agg[x.node_id] = (agg[x.node_id] || 0) + x.count
      })
      return agg
    },
    nodesColor () {
      return Object.entries(this.nodesAggregatedCount).map(([nodeId, count]) => ([
        nodeId,
        this.selectedNodes.includes(parseInt(nodeId)) ? '#ffa85c' : count === 0 ? '#eee' : this.isCompleteNode(nodeId) ? '#8bdcbe' : '#46bac2'
      ])).reduce((acu, x) => ({ ...acu, [x[0]]: x[1] }), {})
    }
  },
  methods: {
    goToNode (id) {
      const index = this.scopeNodePath.indexOf(id)
      if (index === -1) this.scopeNodePath.push(id)
      else this.scopeNodePath = this.scopeNodePath.slice(0, index + 1)
    },
    updateColors () {
      if (!this.selectedNodes || !this.graph || !this.graphData) return
      this.graphData.nodes.forEach(node => {
        this.graphData.nodes.update({ id: node.id, color: this.nodesColor[parseInt(node.id)] })
      })
    },
    isCompleteNode (nodeId) {
      const n = this.nodes[nodeId]
      return n.lat && n.lng && n.iso_code
    },
    mergeSelected () {
      if (this.selectedNodes.length < 2) return
      const nodes = this.selectedNodes.map(nodeId => ({
        ...this.nodes[nodeId],
        count: this.mappings.mappings.filter(x => x.node_id === nodeId).reduce((acu, x) => acu + x.count, 0)
      }))
      nodes.sort((a, b) => b.count - a.count)
      const bestNode = this.primaryNode || nodes[0].node_id
      const bestNodeObj = this.nodes[bestNode]
      this.mappings.mappings.filter(x => this.selectedNodes.includes(x.node_id)).forEach(x => {
        x.node_id = bestNode
      })
      const getFirstValue = (param) => bestNodeObj[param] || (nodes.find(n => n[param]) || {})[param]
      for (const param of ['lat', 'lng', 'iso_code']) {
        this.nodes[bestNode][param] = getFirstValue(param)
      }
      this.updatedNodes.push(bestNode)
      this.$set(this, 'mappings', this.mappings)
      this.selectedNodes = []
    },
    save () {
      if (!this.selectedRegion || !this.countryData) {
        this.saveStatus = 'Failed'
      }
      const update = {
        mappings: this.mappings.mappings,
        nodes: [...new Set(this.updatedNodes)].map(nodeId => this.nodes[nodeId])
      }
      this.$http.post(this.api + '/task/' + this.scopeNode.node_id, update).then(response => {
        this.saveStatus = 'Saved'
        this.updatedNodes = []
      }).catch(e => {
        this.saveStatus = 'Failed'
      })
    },
    saveEdit () {
      const node = this.nodes[this.selectedNodes[0]]
      const lat = parseFloat(this.$refs.editLat.value) || null
      const lng = parseFloat(this.$refs.editLng.value) || null
      const iso = this.$refs.editISO.value || null
      const name = this.$refs.editName.value || node.name
      // Assign after parse all values
      node.lat = lat
      node.lng = lng
      node.iso_code = iso
      node.name = name
      this.$set(this.nodes, this.selectedNodes[0], node)
      this.updatedNodes.push(this.selectedNodes[0])
    }
  }
}
</script>

<style>
#app > .graph {
  width: calc(100% - 400px);
  height: 100%;
  position: absolute;
  top: 0;
  left: 400px;
  z-index: -1;
  padding: 0;
  margin: 0;
}
#app > .sidebar {
  width: 380px;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
  padding: 0 10px;
  margin: 0;
  border-right: 1px solid #eee;
}
#app > .sidebar button {
  padding: 4px 10px;
}
#app, body {
  padding: 0;
  margin: 0;
}
#app > .sidebar .path-part {
  display: inline-block;
  padding: 10px 10px;
  font-size: 18px;
}
#app > .sidebar > .path-part > .sep {
  margin-left: 10px;
}
#app > .sidebar > .path-part > .active {
  color: #371ea8;
  text-decoration: underline;
  cursor: pointer;
}
#app > .sidebar > .node-details {
  padding: 5px 10px;
  position: relative;
  border: 1px solid #ccc;
  margin: 5px 0px;
  border-radius: 10px;
}
#app > .sidebar > .node-details > .node-name {
  color: #4378bf;
  text-decoration: underline;
  cursor: pointer;
}
#app > .sidebar > .node-details > .node-count {
  position: absolute;
  right: 10px;
}
#app > .sidebar > .node-details > .primary-selector {
  position: absolute;
  right: 10px;
  bottom: 10px;
}
#app > .sidebar > .merge-button {
  width: calc(100% - 20px);
  margin: 10px;
}
</style>

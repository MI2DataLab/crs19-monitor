<template>
  <div id="app">
    <div class="sidebar">
      <h3>Choose country</h3>
      <select @change="updateCountry($event.target.value)">
        <option></option>
        <option v-for="region in regions" :key="region.label" :selected="region === selectedRegion">{{ region.label }}</option>
      </select>
      <div>
        <button v-if="regions.indexOf(selectedRegion) > 0" @click="selectedRegion = regions[regions.indexOf(selectedRegion) - 1]">Prev</button>
        <button v-if="regions.indexOf(selectedRegion) < regions.length" @click="selectedRegion = regions[regions.indexOf(selectedRegion) + 1]">Next</button>
      </div>
      <h3>Selected Nodes</h3>
      <span v-for="node in selectedNodes" :key="node">{{ node }} ({{ countryData.nodes.filter(x => x.full_name === node).reduce((acu, x) => acu + x.count, 0) }})<br></span>
      <button v-if="selectedNodes.length > 1" @click="mergeSelected">Merge</button>
      <h3>Save results</h3>
      <button v-if="selectedRegion" @click="save">Save</button>
      <span>{{ saveStatus }}</span>
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
      regions: [],
      selectedRegion: null,
      countryData: null,
      selectedNodes: [],
      graphData: null,
      saveStatus: null,
      api: null
    }
  },
  created () {
    this.api = new URLSearchParams(window.location.search).get('api')
    this.$http.get(this.api).then(response => {
      this.regions = response.body.map(x => ({ ...x, label: x.continent + '/' + x.country }))
    })
  },
  watch: {
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
        if (e.nodes.length === 0) this.selectedNodes = []
        else if (this.selectedNodes.includes(e.nodes[0])) {
          this.selectedNodes = this.selectedNodes.filter(n => n !== e.nodes[0])
        } else {
          this.selectedNodes.push(e.nodes[0])
        }
      })
    },
    selectedNodes () {
      if (!this.selectedNodes || !this.graph || !this.graphData) return
      this.graphData.nodes.forEach(node => {
        this.graphData.nodes.update({ id: node.id, color: this.selectedNodes.includes(node.id) ? 'green' : null })
      })
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
    }
  },
  computed: {
    transformedData () {
      if (!this.countryData) return
      const groups = this.countryData.nodes.reduce((acu, v) => {
        acu[v.full_name] = [...(acu[v.full_name] || []), v.simple_name]
        return acu
      }, {})
      const nodes = Object.entries(groups).map(([fullName, simpleNames]) => ({ id: fullName, label: fullName + '\n-------------\n' + simpleNames.join('\n') }))
      let edges = this.countryData.edges
      const simpleToFull = this.countryData.nodes.reduce((acu, v) => ({ ...acu, [v.simple_name]: v.full_name }))
      edges = edges.map(edge => ({ ...edge, a: simpleToFull[edge.a], b: simpleToFull[edge.b] })).filter(x => x.a !== x.b)
      const edgesMap = {}
      edges.forEach(edge => {
        const nds = [edge.a, edge.b]
        nds.sort()
        edgesMap[nds[0]] = edgesMap[nds[0]] || {}
        edgesMap[nds[0]][nds[1]] = (edgesMap[nds[0]][nds[1]] || 0) < edge.similarity ? edge.similarity : (edgesMap[nds[0]][nds[1]] || 0)
      })
      edges = Object.keys(edgesMap).map(a => Object.keys(edgesMap[a]).map(b => ({ a, b, similarity: edgesMap[a][b] }))).flat()
      edges.sort((a, b) => b.similarity - a.similarity)
      edges = edges.slice(0, 30).map(x => ({ from: x.a, to: x.b, length: 150 + 100 * (1 - x.similarity) }))
      // const edges = new DataSet([])
      return { nodes, edges }
    }
  },
  methods: {
    updateCountry (label) {
      this.selectedRegion = this.regions.find(r => r.label === label)
    },
    mergeSelected () {
      if (this.selectedNodes.length < 2) return
      const nodes = this.countryData.nodes.filter(n => this.selectedNodes.includes(n.full_name))
      nodes.sort((a, b) => b.count - a.count)
      const newName = nodes[0].full_name
      nodes.forEach(n => {
        n.full_name = newName
      })
      this.$set(this, 'countryData', this.countryData)
      this.selectedNodes = []
    },
    save () {
      if (!this.selectedRegion || !this.countryData) {
        this.saveStatus = 'Failed'
      }
      this.$http.post(this.api + 'task/' + this.selectedRegion.continent + '/' + this.selectedRegion.country + '/', this.countryData).then(response => {
        this.saveStatus = 'Saved'
      }).catch(e => {
        this.saveStatus = 'Failed'
      })
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
  width: 400px;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
  padding: 0;
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
</style>

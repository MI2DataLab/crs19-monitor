import React from 'react';
import './App.css';
import Menu from "./components/Menu";
import {
    Switch,
    Route, BrowserRouter,
} from "react-router-dom";
import PolandVOC from "./pages/PolandVOC";
import PolandTrends from "./pages/PolandTrends";
import PolandProvinces from "./pages/PolandProvinces";
import EuropeMutations from "./pages/EuropeMutations";
import PolandStations from "./pages/PolandStations";
import EuropeVOC from "./pages/EuropeVOC";
import CoInfections from "./pages/Coinfections";
import EuropeVOHC from "./pages/EuropeVOHC";
import EuropeVOI from "./pages/EuropeVOI";
import EuropeVUM from "./pages/EuropeVUM";
import ForeignDetections from "./pages/ForeignDetections";
import PolandAge from "./pages/PolandAge";

function App() {
  return (
        <div className="App">
            <BrowserRouter basename={''}>
                <Menu/>
                  <Route path={`/poland/voc`}>
                        <PolandVOC/>
                  </Route>
                <Route path={`/poland/trends`}>
                    <PolandTrends/>
                </Route>
                <Route path={`/poland/regions`}>
                    <PolandProvinces/>
                </Route>
                <Route path={`/poland/age`}>
                    <PolandAge/>
                </Route>
                <Route path={`/europe/proportions`}>
                    <EuropeMutations/>
                </Route>
                <Route path={`/poland/stations`}>
                    <PolandStations/>
                </Route>
                <Route path={`/europe/voc`}>
                    <EuropeVOC/>
                </Route>
                <Route path={`/co-infections`}>
                    <CoInfections/>
                </Route>
                <Route path={`/foreign-detections`}>
                    <ForeignDetections/>
                </Route>
                <Route path={`/europe/vohc`}>
                    <EuropeVOHC/>
                </Route>
                <Route path={`/europe/voi`}>
                    <EuropeVOI/>
                </Route>
                <Route path={`/europe/vum`}>
                    <EuropeVUM/>
                </Route>
                  <Route exact path={`/`}>
                        <PolandVOC/>
                  </Route>
            </BrowserRouter>
        </div>

  );
}

export default App;

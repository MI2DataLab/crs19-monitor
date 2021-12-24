import React from "react";
import { Link } from "react-router-dom";

function Menu(): JSX.Element {
    return <header>
        <div className="nav-container">
            <div className="header-block">
                <h1>
                    Mapa RT-COVAR
                </h1>
                <h2>
                    monitor wariantów i&nbsp;mutacji SARS-COV-2
                </h2>
            </div>
            <nav>
                <div className="nav-block">
                    <h3 className="nav-block__title nav-block__title--bold">Warianty w Polsce

                    </h3>
                    <ul className="nav-block__menu">
                        <li><Link to={`/poland/voc`}>VOC</Link></li>
                        <li><Link to={`/poland/regions`}>Województwa</Link></li>
                        <li><Link to={`/poland/trends`}>Trendy</Link></li>
                        <li><Link to={`/poland/age`}>Wiek</Link></li>
                        <li><Link to={`/poland/stations`}>Stacje</Link></li>
                    </ul>
                </div>
                <div className="nav-block">
                    <h3 className="nav-block__title nav-block__title--bold">Warianty na świecie

                    </h3>
                    <ul className="nav-block__menu">
                        <li><Link to={`/europe/proportions`}>Proporcje</Link></li>
                        <li><Link to={`/europe/voc`}>VOC</Link></li>
                        <li><Link to={`/europe/vohc`}>VOHC</Link></li>
                        <li><Link to={`/europe/voi`}>VOI</Link></li>
                        <li><Link to={`/europe/vum`}>VUM</Link></li>
                    </ul>
                </div>
                {/*
                <div className="nav-block">
                    <h3 className="nav-block__title nav-block__title--bold">Specjlistyczne raporty</h3>
                    <ul className="nav-block__menu">
                        <li><Link to={`/co-infections`}>Koinfekcje</Link></li>
                        <li><Link to={`/foreign-detections`}>Wykrycia zagraniczne</Link></li>
                    </ul>
                </div>
                <div className="nav-block">
                    <h3 className="nav-block__title nav-block__title--bold">INFO</h3>
                </div>
                */}
            </nav>
        </div>
    </header>;
}

export default Menu;

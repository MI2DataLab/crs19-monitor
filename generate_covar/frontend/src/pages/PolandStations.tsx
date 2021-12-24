import React from "react";
import {Station} from "../domain/station.interface";
import {StationsDataSource} from "../data-access/stations-data-source";
import MaterialTable from "material-table";
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    TextField
} from "@material-ui/core";

export interface State {
    stations: Station[];
    auth: boolean;
    login: string;
    password: string;
}

class PolandStations extends React.Component<{}, State>{
    state: State = {
        stations: [],
        auth: false,
        login: '',
        password: ''
    };
    private instance = new StationsDataSource();
    private handleClose = () => {
        this.instance.fetch(this.state.login, this.state.password).then(
            stations => this.setState({
                stations,
                auth: true
            })
        );
    }

    private changeLogin = (login: string) => this.setState({login});
    private changePassword = (password: string) => this.setState({password});

    render() {
        return <main>
            <div>
                <div className="map-view__header">
                    <div className="map-view__title-section">
                        <h2 className="map-view__title">Zidentyfikowane warianty w stacjach PSSE</h2>
                    </div>
                </div>
                <MaterialTable
                    columns={[
                        { title: "Stacja", field: "Stacja" },
                        { title: "Wariant", field: "Wariant" },
                        { title: "ID wywiadu", field: "ID wywiadu" },
                        { title: "Data pobrania", field: "Data pobrania", type: "date" },
                        { title: "Data sekwencji", field: "Data sekwencji", type: "date" },
                    ]}
                    options={{
                        filtering: true,
                        search: false,
                        showTitle: false
                    }}
                    data={this.state.stations}
                />
            </div>
            <Dialog open={!this.state.auth} onClose={this.handleClose} aria-labelledby="form-dialog-title">
                <DialogTitle>Wymagane logowanie!</DialogTitle>
                <DialogContent>
                    <DialogContentText>
                        Proszę się zalogować.
                    </DialogContentText>
                    <TextField
                        autoFocus
                        margin="dense"
                        id="name"
                        label="Login"
                        onChange={e => this.changeLogin(e.target.value)}
                        type="text"
                        fullWidth
                    />
                    <TextField
                        autoFocus
                        margin="dense"
                        id="password"
                        onChange={e => this.changePassword(e.target.value)}
                        label="Hasło"
                        type="password"
                        fullWidth
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={this.handleClose} color="primary">
                        Login
                    </Button>
                </DialogActions>
            </Dialog>
        </main>;
    }
}

export default PolandStations;
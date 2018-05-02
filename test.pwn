#include <a_samp>
#include <logger>
#include <settings>
#include <requests>
#include <map>


// RequestsClient stores the client information for making requests such as the
// endpoint and headers. Though in this example, we are no using any headers.
new RequestsClient:jsonstore;

public OnGameModeInit() {
    // Load the endpoint from settings.ini
    new endpoint[128];
    GetSettingString("settings.ini", "endpoint", "", endpoint);
    if(endpoint[0] == EOS) {
        fatal("Could not load 'endpoint' from settings.ini");
    }

    // Create the requests client with the endpoint.
    jsonstore = RequestsClient(endpoint);

    return 1;
}

// We're using BigETI's map plugin to simplify the process of knowing which
// player ID triggered which request.
new Map:LoadRequestToPlayerID;

public OnPlayerConnect(playerid) {
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, MAX_PLAYER_NAME);

    // This is our first request - this sends a GET request to jsonstore.io and
    // uses the player's name as the path. The full URL would look something
    // like: `https://jsonstore.io/<key>/Southclaws` for my username.
    new Request:id = RequestJSON(
        jsonstore,       // use the jsonstore client
        name,            // use the player's name as the URL path
        HTTP_METHOD_GET, // use the HTTP GET method
        "OnLoadData"     // call OnLoadData when the response arrives
    );

    // map the request ID to the player ID
    MAP_insert_val_val(LoadRequestToPlayerID, _:id, playerid);
}

// quick player position enumerator and variable to store it
enum E_POSITION { Float:POS_X, Float:POS_Y, Float:POS_Z }
new PlayerPosition[MAX_PLAYERS][E_POSITION];

// OnLoadData is called when the request made in OnPlayerConnect has finished
// and jsonstore.io has responded with data
forward OnLoadData(Request:id, E_HTTP_STATUS:status, Node:node);
public OnLoadData(Request:id, E_HTTP_STATUS:status, Node:node) {
    // get the player's ID from the request ID that was stored in
    // OnPlayerConnect
    new playerid = MAP_get_val_val(LoadRequestToPlayerID, _:id);
    MAP_remove_val(LoadRequestToPlayerID, _:id);

    // jsonstore.io always uses OK status, even if the data is missing
    if(status != HTTP_STATUS_OK) {
        SendClientMessage(playerid, -1, "An unknown error occurred!");
        err("response status was not OK",
            _i("playerid", playerid),
            _i("status", _:status));
    }

    // jsonstore.io always responds with an object with two fields:
    // "ok"
    // "result"
    // ok is a bool that indicates if the document exists, so check we check it:
    new bool:ok;
    JsonGetBool(node, "ok", ok);
    if(!ok) {
        // this is the equivalent of a "404 not found"

        SendClientMessage(playerid, -1, "Welcome to the server, first-timer!");
        // set the player's position to a sane default
        PlayerPosition[playerid][POS_X] = 0.0;
        PlayerPosition[playerid][POS_Y] = 0.0;
        PlayerPosition[playerid][POS_Z] = 3.0;

        // return, nothing else to do
        return;
    }

    // now, the result exists so extract it as a JSON object
    new Node:result;
    JsonGetObject(node, "result", result);

    // then use JSON float functions to get the x, y, z values out of the result
    JsonGetFloat(result, "x", PlayerPosition[playerid][POS_X]);
    JsonGetFloat(result, "y", PlayerPosition[playerid][POS_Y]);
    JsonGetFloat(result, "z", PlayerPosition[playerid][POS_Z]);

    SendClientMessage(playerid, -1, "Welcome back!");

    log("player data loaded",
        _i("playerid", playerid));

}

// When the player spawns, use the positions that were acquired in OnLoadData
public OnPlayerSpawn(playerid) {
    SetPlayerPos(
        playerid,
        PlayerPosition[playerid][POS_X],
        PlayerPosition[playerid][POS_Y],
        PlayerPosition[playerid][POS_Z]);

    return 1;
}

new Map:SaveRequestToPlayerID;

// When the player disconnects, we want to grab their position and then store it
// to jsonstore.io using the player's name as the URL path
public OnPlayerDisconnect(playerid, reason) {
    new
        name[MAX_PLAYER_NAME],
        Float:x,
        Float:y,
        Float:z;

    GetPlayerName(playerid, name, MAX_PLAYER_NAME);
    GetPlayerPos(playerid, x, y, z);

    // Sends a POST request to jsonstore.io with a JSON object built inline
    new Request:id = RequestJSON(
        jsonstore,        // use the jsonstore client
        name,             // use the player's name as the URL path
        HTTP_METHOD_POST, // use the HTTP POST method
        "OnSaveData",     // call OnSaveData when the request has finished
        JsonObject(       // construct a JSON object with 3 values and return it
            "x", JsonFloat(x),
            "y", JsonFloat(y),
            "z", JsonFloat(z)
        )
    );

    // Same map strategy as with the loading data process
    MAP_insert_val_val(SaveRequestToPlayerID, _:id, playerid);
}

forward OnSaveData(Request:id, E_HTTP_STATUS:status, Node:node);
public OnSaveData(Request:id, E_HTTP_STATUS:status, Node:node) {
    new playerid = MAP_get_val_val(SaveRequestToPlayerID, _:id);
    MAP_remove_val(SaveRequestToPlayerID, _:id);

    if(status != HTTP_STATUS_CREATED) {
        err("failed to POST player data",
            _i("playerid", playerid),
            _i("status", _:status));
    } else {
        log("player data stored",
            _i("playerid", playerid));
    }
}

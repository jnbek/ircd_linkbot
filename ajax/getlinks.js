/* Configuration */
var json_file = 'network_links.json';
/* END Configuration */
var req = getXHR();

function getXHR() {
    if (window.XMLHttpRequest) {
        return new XMLHttpRequest;
    } else if (window.ActiveXObject) {
        return new ActiveXObject("Microsoft.XMLHTTP");
    } else {
        alert("Status: Cound not create XmlHttpRequest Object.Consider upgrading your browser.");
    }
}
function getJSON() {
    if (req.readyState == 4 || req.readyState == 0) {
        req.open("GET", json_file, true);
        req.onreadystatechange = respHandler;
        req.send(null);
    }
}
function respHandler() {
    if (req.readyState == 4) {
        var tbl_code = null;
        var destElem = document.getElementById("server_links");
        var response = eval("(" + req.responseText + ")");
        tbl_code = "<table class='irc_stats'>";
        tbl_code += "<tr><th>Server:</th><th>Uptime:</th></tr>";
        for (var i = 0; i < response.length; i++) {
            tbl_code += "<tr><td class='server_1'>"+response[i].name+"</td>";
            tbl_code += "<td class='server_1'>"+response[i].uptime+"</td></tr>";
        }
        tbl_code += "</table>";
        destElem.innerHTML = tbl_code;
        console.log(tbl_code);
    }
}
